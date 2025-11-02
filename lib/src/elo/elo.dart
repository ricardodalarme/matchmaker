import 'dart:math' as math;

import 'package:matchmaker/src/elo/elo_rating.dart';
import 'package:matchmaker/src/match_result.dart';

/// The Elo rating system for competitive games.
///
/// Developed by Arpad Elo for chess, this system uses a simple numerical
/// approach where rating differences translate directly to win probabilities.
///
/// Unlike Glicko-2, Elo doesn't track uncertainty or volatility - just a
/// single rating number that goes up when you win and down when you lose.
class Elo {
  /// Creates an Elo rating system.
  ///
  /// [kFactor] determines how much ratings change per game. Higher values
  /// mean ratings adjust faster. Common values:
  /// - 32: For amateur/active players (USCF standard)
  /// - 24: For intermediate players
  /// - 16: For masters
  /// - 10: For high-level play (FIDE standard)
  ///
  /// [defaultRating] is the starting rating for new players (usually 1500).
  const Elo({
    this.kFactor = 32,
    this.defaultRating = 1500,
  });

  /// The K-factor that controls rating change magnitude.
  ///
  /// Higher values (32) make ratings adjust faster, good for newer or
  /// more volatile players. Lower values (10-16) make ratings more stable,
  /// suitable for established players.
  final double kFactor;

  /// Default rating for new players.
  final double defaultRating;

  /// Calculates a new rating after a series of games.
  ///
  /// [currentRating] is the player's rating before the games.
  /// [results] is the list of match outcomes during the period.
  ///
  /// Returns the updated rating after processing all matches.
  EloRating calculateNewRating(
    EloRating currentRating,
    List<MatchResult<EloRating>> results,
  ) {
    if (results.isEmpty) {
      return currentRating;
    }

    var totalExpectedScore = 0.0;
    var totalActualScore = 0.0;

    for (final result in results) {
      totalActualScore += result.score;
      totalExpectedScore += _calculateExpectedScore(
        currentRating.rating,
        result.opponent.rating,
      );
    }

    final newRating = currentRating.rating + kFactor * (totalActualScore - totalExpectedScore);

    return EloRating(rating: newRating);
  }

  /// Predicts the expected score (win probability) between two players.
  ///
  /// Returns a value between 0 and 1 representing the first player's
  /// expected score. A value of 0.5 means evenly matched players.
  /// 0.75 means the player is expected to score 75% (3 out of 4 games).
  double predictOutcome(EloRating player, EloRating opponent) {
    return _calculateExpectedScore(player.rating, opponent.rating);
  }

  /// Calculates expected score based on rating difference.
  ///
  /// Uses the logistic function: 1 / (1 + 10^(-D/400))
  /// where D is the rating difference.
  double _calculateExpectedScore(double playerRating, double opponentRating) {
    final ratingDifference = playerRating - opponentRating;
    return 1.0 / (1.0 + math.pow(10, -ratingDifference / 400));
  }

  /// Gets the rating difference that corresponds to a given win probability.
  ///
  /// This is the inverse of the expected score calculation.
  /// For example, if you want to know how many rating points difference
  /// corresponds to a 75% expected score, pass 0.75.
  double getRatingDifferenceForProbability(double probability) {
    assert(
      probability > 0 && probability < 1,
      'Probability must be between 0 and 1 (exclusive)',
    );
    return -400 * math.log(1 / probability - 1) / math.ln10;
  }
}
