import 'dart:math' as math;

import 'package:matchmaker/src/glicko2/glicko2_math.dart';
import 'package:matchmaker/src/glicko2/glicko2_rating.dart';
import 'package:matchmaker/src/glicko2/glicko2_scale.dart';
import 'package:matchmaker/src/glicko2/match_result.dart';

typedef _OpponentData = ({double mu, double phi, double score});

/// The Glicko-2 rating system implementation.
///
/// Glicko-2 is a rating system for assessing player skill in competitive games.
/// It extends the original Glicko system by adding a volatility parameter that
/// measures the degree of expected fluctuation in a player's rating.
///
/// This implementation follows the algorithm described by Dr. Mark E. Glickman.
/// See: http://www.glicko.net/glicko/glicko2.pdf
class Glicko2 {
  /// Creates a Glicko-2 rating system.
  ///
  /// - [tau]: Volatility constraint (default: 0.5, range: 0.3-1.2)
  /// - [defaultRating]: Starting rating for new players (default: 1500)
  /// - [defaultRd]: Starting RD for new players (default: 350)
  /// - [defaultVolatility]: Starting volatility for new players (default: 0.06)
  /// - [epsilon]: Convergence tolerance for calculations (default: 0.000001)
  const Glicko2({
    this.tau = 0.5,
    this.defaultRating = 1500.0,
    this.defaultRd = 350.0,
    this.defaultVolatility = 0.06,
    this.epsilon = 0.000001,
  });

  /// System constant that constrains volatility change over time.
  ///
  /// Reasonable values are between 0.3 and 1.2. Smaller values prevent
  /// volatility from changing drastically.
  final double tau;

  /// Default rating for new/unrated players.
  final double defaultRating;

  /// Default rating deviation for new/unrated players.
  final double defaultRd;

  /// Default volatility for new/unrated players.
  final double defaultVolatility;

  /// Convergence tolerance for volatility calculation.
  final double epsilon;

  /// Glicko-2 scale conversion constant
  static const double scalingFactor = 173.7178;

  /// Calculates updated rating after a rating period with match results.
  ///
  /// [currentRating] is the player's rating at the start of the period.
  /// [results] is the list of match outcomes during the period.
  ///
  /// Returns the updated rating after processing all matches.
  ///
  /// If [results] is empty, only applies rating deviation decay (for inactive players).
  Glicko2Rating calculateNewRating(
    Glicko2Rating currentRating,
    List<MatchResult> results,
  ) {
    final mu = currentRating.rating.toGlicko2Scale();
    final phi = currentRating.rd / scalingFactor;
    final sigma = currentRating.volatility;

    if (results.isEmpty) {
      final phiStar = math.sqrt(phi * phi + sigma * sigma);
      return Glicko2Rating(
        rating: currentRating.rating,
        rd: phiStar * scalingFactor,
        volatility: sigma,
      );
    }

    final opponentData = results
        .map(
          (result) => (
            mu: result.opponent.rating.toGlicko2Scale(),
            phi: result.opponent.rd / scalingFactor,
            score: result.score,
          ),
        )
        .toList();

    final v = _computeVariance(mu, opponentData);
    final delta = _computeDelta(mu, opponentData, v);
    final sigmaPrime = _computeNewVolatility(phi, v, delta, sigma);

    final phiStar = math.sqrt(phi * phi + sigmaPrime * sigmaPrime);
    final phiPrime = 1.0 / math.sqrt(1.0 / (phiStar * phiStar) + 1.0 / v);
    final muPrime =
        mu + phiPrime * phiPrime * _computeDeltaSum(mu, opponentData);

    return Glicko2Rating(
      rating: muPrime.fromGlicko2Scale(),
      rd: phiPrime * scalingFactor,
      volatility: sigmaPrime,
    );
  }

  /// Predicts the expected outcome of a match between two players.
  ///
  /// Returns the probability (0.0 to 1.0) that [player] will beat [opponent].
  /// Takes into account the uncertainty (RD) of both players' ratings.
  ///
  /// A value of 0.5 indicates evenly matched players.
  /// Higher values favor the player, lower values favor the opponent.
  double predictOutcome(Glicko2Rating player, Glicko2Rating opponent) {
    final g = Glicko2Math.g(
      math.sqrt(
        player.rd * player.rd + opponent.rd * opponent.rd,
      ),
    );
    final exponent = -g * (player.rating - opponent.rating) / 400.0;
    return 1.0 / (1.0 + math.pow(10, exponent));
  }

  /// Applies rating deviation increase for a player who did not compete.
  ///
  /// When a player doesn't compete for a rating period, their RD increases
  /// to reflect increased uncertainty about their skill level.
  ///
  /// [currentRating] is the player's current rating.
  /// Returns the rating with increased RD.
  Glicko2Rating applyRatingPeriodWithoutGames(Glicko2Rating currentRating) {
    return calculateNewRating(currentRating, []);
  }

  double _computeVariance(
    double mu,
    List<_OpponentData> opponentData,
  ) {
    double sum = 0;
    for (final opponent in opponentData) {
      final g = Glicko2Math.g(opponent.phi * scalingFactor);
      final e = Glicko2Math.e(mu, opponent.mu, opponent.phi);
      sum += g * g * e * (1.0 - e);
    }
    return 1.0 / sum;
  }

  double _computeDelta(
    double mu,
    List<_OpponentData> opponentData,
    double v,
  ) {
    return v * _computeDeltaSum(mu, opponentData);
  }

  double _computeDeltaSum(
    double mu,
    List<_OpponentData> opponentData,
  ) {
    double sum = 0;
    for (final opponent in opponentData) {
      final g = Glicko2Math.g(opponent.phi * scalingFactor);
      final e = Glicko2Math.e(mu, opponent.mu, opponent.phi);
      sum += g * (opponent.score - e);
    }
    return sum;
  }

  double _computeNewVolatility(
    double phi,
    double v,
    double delta,
    double sigma,
  ) {
    final a = math.log(sigma * sigma);

    double f(double x) {
      final eX = math.exp(x);
      final phi2 = phi * phi;
      final delta2 = delta * delta;

      final numerator = eX * (delta2 - phi2 - v - eX);
      final denominator = 2.0 * math.pow(phi2 + v + eX, 2);
      final subtraction = (x - a) / (tau * tau);

      return numerator / denominator - subtraction;
    }

    double A = a;
    double B;

    if (delta * delta > phi * phi + v) {
      B = math.log(delta * delta - phi * phi - v);
    } else {
      int k = 1;
      while (f(a - k * tau) < 0) {
        k++;
      }
      B = a - k * tau;
    }

    double fA = f(A);
    double fB = f(B);

    while ((B - A).abs() > epsilon) {
      final C = A + (A - B) * fA / (fB - fA);
      final fC = f(C);

      if (fC * fB <= 0) {
        A = B;
        fA = fB;
      } else {
        fA = fA / 2.0;
      }

      B = C;
      fB = fC;
    }

    return math.exp(A / 2.0);
  }
}
