import 'dart:math' as math;

import 'package:matchmaker/src/trueskill/trueskill_rating.dart';

/// The TrueSkill rating system for competitive games.
///
/// TrueSkill is a Bayesian skill rating system developed by Microsoft Research.
/// It extends the concepts of Elo and Glicko by:
/// - Supporting team-based games
/// - Handling free-for-all (multiplayer) matches
/// - Tracking skill uncertainty separately from skill level
///
/// Each player has a skill represented by a Gaussian distribution N(μ, σ²):
/// - μ (mu): The mean skill level
/// - σ (sigma): The uncertainty/standard deviation
///
/// The system uses factor graphs and Gaussian message passing for updates.
class TrueSkill {
  /// Creates a TrueSkill rating system.
  ///
  /// [mu] is the default mean skill for new players (default: 25.0).
  /// [sigma] is the default uncertainty for new players (default: mu/3 ≈ 8.333).
  /// [beta] is the skill class width (default: sigma/2 ≈ 4.167).
  /// [tau] is the dynamics factor that prevents sigma from getting too low.
  /// [drawProbability] is the probability of a draw in the game (default: 0.10).
  const TrueSkill({
    this.mu = 25.0,
    double? sigma,
    double? beta,
    double? tau,
    this.drawProbability = 0.10,
  })  : sigma = sigma ?? mu / 3,
        beta = beta ?? (sigma ?? mu / 3) / 2,
        tau = tau ?? (sigma ?? mu / 3) / 100;

  /// Default mean skill for new players.
  final double mu;

  /// Default skill uncertainty for new players.
  final double sigma;

  /// Skill class width - the distance that yields ~76% win probability.
  ///
  /// This represents performance variance in a single game. A smaller beta
  /// means game outcomes are more deterministic.
  final double beta;

  /// Dynamics factor - prevents sigma from decreasing too much.
  ///
  /// This models the idea that player skill can change over time,
  /// preventing the system from becoming too confident.
  final double tau;

  /// The probability of a draw occurring in this game type.
  final double drawProbability;

  /// Creates a new rating with the environment defaults.
  ///
  /// Optionally override [mu] and/or [sigma] for specific players.
  TrueSkillRating createRating({double? mu, double? sigma}) {
    return TrueSkillRating(
      mu: mu ?? this.mu,
      sigma: sigma ?? this.sigma,
    );
  }

  /// Calculates new ratings after a match.
  ///
  /// [teams] is a list of teams, where each team is a list of player ratings.
  /// For 1v1, this would be `[[player1], [player2]]`.
  /// For team matches, e.g., `[[alice, bob], [carol, dave]]`.
  ///
  /// [ranks] optionally specifies the finishing position of each team.
  /// Lower rank = better placement (0 = first place, 1 = second, etc.).
  /// Teams with the same rank are considered to have drawn.
  /// If not provided, assumes teams are ordered by finishing position.
  ///
  /// [weights] optionally specifies participation weights for each player.
  /// Use this for partial play (e.g., player joined mid-game).
  /// Default weight is 1.0 (full participation).
  ///
  /// Returns a list of teams with updated ratings in the same structure.
  List<List<TrueSkillRating>> rate(
    List<List<TrueSkillRating>> teams, {
    List<int>? ranks,
    List<List<double>>? weights,
  }) {
    if (teams.length < 2) {
      throw ArgumentError('At least 2 teams are required');
    }

    // Default ranks: 0, 1, 2, ... (assumes teams are in finishing order)
    ranks ??= List.generate(teams.length, (i) => i);

    if (ranks.length != teams.length) {
      throw ArgumentError('Ranks length must match teams length');
    }

    // Default weights: all 1.0
    weights ??= teams.map((team) => List<double>.filled(team.length, 1)).toList();

    // Sort teams by rank for processing
    final sortedIndices = List.generate(teams.length, (i) => i)
      ..sort((a, b) => ranks![a].compareTo(ranks[b]));

    final sortedTeams = sortedIndices.map((i) => teams[i]).toList();
    final sortedRanks = sortedIndices.map((i) => ranks![i]).toList();
    final sortedWeights = sortedIndices.map((i) => weights![i]).toList();

    // Apply tau (dynamics) to increase uncertainty before update
    final teamsWithTau = sortedTeams
        .map(
          (team) => team
              .map(
                (r) => TrueSkillRating(
                  mu: r.mu,
                  sigma: math.sqrt(r.sigma * r.sigma + tau * tau),
                ),
              )
              .toList(),
        )
        .toList();

    // Calculate updates using factor graph approximation
    final updatedTeams = _calculateUpdates(
      teamsWithTau,
      sortedRanks,
      sortedWeights,
    );

    // Restore original ordering
    final result = List<List<TrueSkillRating>>.filled(teams.length, []);
    for (var i = 0; i < sortedIndices.length; i++) {
      result[sortedIndices[i]] = updatedTeams[i];
    }

    return result;
  }

  /// Calculates the match quality between teams.
  ///
  /// Returns a value between 0 and 1, where higher values indicate
  /// a more balanced match (closer to 50/50 outcome probability).
  ///
  /// For 1v1: quality = draw_probability when skills are equal.
  double quality(List<List<TrueSkillRating>> teams) {
    if (teams.length != 2) {
      // For multi-team, use pairwise average
      var totalQuality = 0.0;
      var count = 0;
      for (var i = 0; i < teams.length; i++) {
        for (var j = i + 1; j < teams.length; j++) {
          totalQuality += _twoTeamQuality(teams[i], teams[j]);
          count++;
        }
      }
      return count > 0 ? totalQuality / count : 0.0;
    }
    return _twoTeamQuality(teams[0], teams[1]);
  }

  /// Predicts the win probability for player against opponent in 1v1.
  ///
  /// Returns the probability (0.0 to 1.0) that [player] will beat [opponent].
  double predictWin(TrueSkillRating player, TrueSkillRating opponent) {
    final deltaMu = player.mu - opponent.mu;
    final sumSigmaSq =
        player.sigma * player.sigma + opponent.sigma * opponent.sigma + 2 * beta * beta;
    final denom = math.sqrt(sumSigmaSq);
    return _cdf(deltaMu / denom);
  }

  double _twoTeamQuality(
    List<TrueSkillRating> team1,
    List<TrueSkillRating> team2,
  ) {
    // Team skill aggregation
    final mu1 = team1.fold<double>(0, (sum, r) => sum + r.mu);
    final mu2 = team2.fold<double>(0, (sum, r) => sum + r.mu);

    final sigmaSq1 = team1.fold<double>(0, (sum, r) => sum + r.sigma * r.sigma);
    final sigmaSq2 = team2.fold<double>(0, (sum, r) => sum + r.sigma * r.sigma);

    final n = team1.length + team2.length;
    final betaSq = beta * beta;

    final totalSigmaSq = sigmaSq1 + sigmaSq2 + n * betaSq;
    final deltaMu = mu1 - mu2;

    // Quality formula based on draw probability approximation
    final sqrtPart = math.sqrt(n * betaSq / totalSigmaSq);
    final expPart = math.exp(-deltaMu * deltaMu / (2 * totalSigmaSq));

    return sqrtPart * expPart;
  }

  List<List<TrueSkillRating>> _calculateUpdates(
    List<List<TrueSkillRating>> teams,
    List<int> ranks,
    List<List<double>> weights,
  ) {
    // For each adjacent pair of teams, calculate the update
    final teamMus = teams.map((team) => team.fold<double>(0, (sum, r) => sum + r.mu)).toList();
    final teamSigmaSqs = teams
        .map(
          (team) => team.fold<double>(0, (sum, r) => sum + r.sigma * r.sigma),
        )
        .toList();

    // Calculate the update for each team
    final teamMuDeltas = List<double>.filled(teams.length, 0);
    final teamSigmaMultipliers = List<double>.filled(teams.length, 1);

    for (var i = 0; i < teams.length - 1; i++) {
      final j = i + 1;

      // Combined variance for comparison
      final c = math.sqrt(
        teamSigmaSqs[i] + teamSigmaSqs[j] + (teams[i].length + teams[j].length) * beta * beta,
      );

      final deltaMu = teamMus[i] - teamMus[j];

      // Draw margin
      final drawMargin = _calculateDrawMargin(c);

      // Is this a draw (same rank)?
      final isDraw = ranks[i] == ranks[j];

      // Calculate v and w functions
      double v;
      double w;
      if (isDraw) {
        v = _vDraw(deltaMu / c, drawMargin / c);
        w = _wDraw(deltaMu / c, drawMargin / c);
      } else {
        v = _vWin(deltaMu / c, drawMargin / c);
        w = _wWin(deltaMu / c, drawMargin / c);
      }

      // Distribute the update across teams
      final sigmaSqToC1 = teamSigmaSqs[i] / c;
      final sigmaSqToC2 = teamSigmaSqs[j] / c;

      teamMuDeltas[i] += sigmaSqToC1 * v;
      teamMuDeltas[j] -= sigmaSqToC2 * v;

      final sigmaMulti1 = math.sqrt(1 - w * teamSigmaSqs[i] / (c * c));
      final sigmaMulti2 = math.sqrt(1 - w * teamSigmaSqs[j] / (c * c));

      teamSigmaMultipliers[i] *= sigmaMulti1.isNaN ? 1.0 : sigmaMulti1;
      teamSigmaMultipliers[j] *= sigmaMulti2.isNaN ? 1.0 : sigmaMulti2;
    }

    // Distribute team updates to individual players
    final result = <List<TrueSkillRating>>[];

    for (var teamIdx = 0; teamIdx < teams.length; teamIdx++) {
      final team = teams[teamIdx];
      final teamWeight = weights[teamIdx];
      final teamSigmaSq = teamSigmaSqs[teamIdx];

      final updatedPlayers = <TrueSkillRating>[];

      for (var playerIdx = 0; playerIdx < team.length; playerIdx++) {
        final player = team[playerIdx];
        final weight = teamWeight[playerIdx];
        final playerSigmaSq = player.sigma * player.sigma;

        // Player's contribution to the team
        final contribution = weight * playerSigmaSq / teamSigmaSq;

        final newMu = player.mu + contribution * teamMuDeltas[teamIdx];
        final newSigma = player.sigma * teamSigmaMultipliers[teamIdx];

        updatedPlayers.add(
          TrueSkillRating(
            mu: newMu,
            sigma: math.max(newSigma, sigma / 100), // Minimum sigma
          ),
        );
      }

      result.add(updatedPlayers);
    }

    return result;
  }

  double _calculateDrawMargin(double c) {
    // Convert draw probability to margin
    return _ppf((1 + drawProbability) / 2) * c;
  }

  // Gaussian PDF
  double _pdf(double x) {
    return math.exp(-0.5 * x * x) / math.sqrt(2 * math.pi);
  }

  // Gaussian CDF (approximation)
  double _cdf(double x) {
    return 0.5 * (1 + _erf(x / math.sqrt(2)));
  }

  // Error function approximation (Abramowitz and Stegun)
  double _erf(double x) {
    final sign = x < 0 ? -1 : 1;
    final absX = x.abs();

    const a1 = 0.254829592;
    const a2 = -0.284496736;
    const a3 = 1.421413741;
    const a4 = -1.453152027;
    const a5 = 1.061405429;
    const p = 0.3275911;

    final t = 1.0 / (1.0 + p * absX);
    final y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-absX * absX);

    return sign * y;
  }

  // Inverse CDF (PPF) - approximation
  double _ppf(double p) {
    if (p <= 0) return double.negativeInfinity;
    if (p >= 1) return double.infinity;
    if (p == 0.5) return 0;

    // Rational approximation for lower region
    if (p < 0.5) {
      return -_ppf(1 - p);
    }

    final t = math.sqrt(-2.0 * math.log(1 - p));

    const c0 = 2.515517;
    const c1 = 0.802853;
    const c2 = 0.010328;
    const d1 = 1.432788;
    const d2 = 0.189269;
    const d3 = 0.001308;

    return t - (c0 + c1 * t + c2 * t * t) / (1 + d1 * t + d2 * t * t + d3 * t * t * t);
  }

  // v function for win case
  double _vWin(double deltaMuOverC, double drawMarginOverC) {
    final x = deltaMuOverC - drawMarginOverC;
    final cdfVal = _cdf(x);
    if (cdfVal < 1e-10) return -x;
    return _pdf(x) / cdfVal;
  }

  // w function for win case
  double _wWin(double deltaMuOverC, double drawMarginOverC) {
    final x = deltaMuOverC - drawMarginOverC;
    final cdfVal = _cdf(x);
    if (cdfVal < 1e-10) return 1;
    final v = _vWin(deltaMuOverC, drawMarginOverC);
    return v * (v + x);
  }

  // v function for draw case
  double _vDraw(double deltaMuOverC, double drawMarginOverC) {
    final absDelta = deltaMuOverC.abs();
    final a = drawMarginOverC - absDelta;
    final b = -drawMarginOverC - absDelta;

    final pdfA = _pdf(a);
    final pdfB = _pdf(b);
    final cdfA = _cdf(a);
    final cdfB = _cdf(b);

    final denom = cdfA - cdfB;
    if (denom.abs() < 1e-10) return 0;

    final sign = deltaMuOverC < 0 ? -1.0 : 1.0;
    return sign * (pdfB - pdfA) / denom;
  }

  // w function for draw case
  double _wDraw(double deltaMuOverC, double drawMarginOverC) {
    final absDelta = deltaMuOverC.abs();
    final a = drawMarginOverC - absDelta;
    final b = -drawMarginOverC - absDelta;

    final pdfA = _pdf(a);
    final pdfB = _pdf(b);
    final cdfA = _cdf(a);
    final cdfB = _cdf(b);

    final denom = cdfA - cdfB;
    if (denom.abs() < 1e-10) return 1;

    final v = _vDraw(deltaMuOverC, drawMarginOverC);
    return v * v + (a * pdfA - b * pdfB) / denom;
  }
}
