import 'dart:math' as math;

import 'package:matchmaker/src/glicko2/glicko2_rating.dart';
import 'package:matchmaker/src/glicko2/match_result.dart';

typedef _OpponentData = ({
  double scaledRating,
  double scaledRatingDeviation,
  double score,
});

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
  /// - [volatilityConstraint]: Volatility constraint (default: 0.5, range: 0.3-1.2)
  /// - [convergenceTolerance]: Convergence tolerance for calculations (default: 0.000001)
  const Glicko2({
    this.volatilityConstraint = 0.5,
    this.convergenceTolerance = 0.000001,
  });

  /// System constant that constrains volatility change over time.
  ///
  /// Reasonable values are between 0.3 and 1.2. Smaller values prevent
  /// volatility from changing drastically.
  final double volatilityConstraint;

  /// Convergence tolerance for volatility calculation.
  final double convergenceTolerance;

  /// Glicko-2 scale conversion constant.
  static const double _scalingFactor = 173.7178;

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
    // Step 2: Convert to Glicko-2 scale
    final scaledRating = _toGlicko2Scale(currentRating.rating);
    final scaledRatingDeviation = currentRating.rd / _scalingFactor;
    final volatility = currentRating.volatility;

    // If no games played, only update RD based on volatility
    if (results.isEmpty) {
      final preRatingDeviation = math.sqrt(
        scaledRatingDeviation * scaledRatingDeviation + volatility * volatility,
      );
      return Glicko2Rating(
        rating: currentRating.rating,
        rd: preRatingDeviation * _scalingFactor,
        volatility: volatility,
      );
    }

    final List<_OpponentData> opponentData = results
        .map(
          (result) => (
            scaledRating: _toGlicko2Scale(result.opponent.rating),
            scaledRatingDeviation: result.opponent.rd / _scalingFactor,
            score: result.score,
          ),
        )
        .toList();

    // Step 3: Compute variance
    final variance = _computeVariance(scaledRating, opponentData);

    // Step 4: Compute delta
    final delta = _computeDelta(scaledRating, opponentData, variance);

    // Step 5: Determine new volatility
    final newVolatility = _computeNewVolatility(
      scaledRatingDeviation,
      variance,
      delta,
      volatility,
    );

    // Step 6: Update rating deviation to pre-rating period value
    final preRatingDeviation = math.sqrt(
      scaledRatingDeviation * scaledRatingDeviation + newVolatility * newVolatility,
    );

    // Step 7: Update rating and RD to new values
    final newScaledRatingDeviation = 1.0 /
        math.sqrt(
          1.0 / (preRatingDeviation * preRatingDeviation) + 1.0 / variance,
        );
    final newScaledRating = scaledRating +
        newScaledRatingDeviation *
            newScaledRatingDeviation *
            _computeDeltaSum(scaledRating, opponentData);

    // Step 8: Convert back to original scale
    return Glicko2Rating(
      rating: _fromGlicko2Scale(newScaledRating),
      rd: newScaledRatingDeviation * _scalingFactor,
      volatility: newVolatility,
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
    final g = _gFunction(
      math.sqrt(
        player.rd * player.rd + opponent.rd * opponent.rd,
      ),
    );
    final exponent = -g * (player.rating - opponent.rating) / 400.0;
    return 1.0 / (1.0 + math.pow(10, exponent));
  }

  double _toGlicko2Scale(double rating) {
    return (rating - 1500.0) / _scalingFactor;
  }

  double _fromGlicko2Scale(double scaledRating) {
    return scaledRating * _scalingFactor + 1500.0;
  }

  double _gFunction(double ratingDeviation) {
    final scaledRd = ratingDeviation / _scalingFactor;
    return 1.0 / math.sqrt(1.0 + 3.0 * scaledRd * scaledRd / (math.pi * math.pi));
  }

  double _eFunction(
    double scaledRating,
    double opponentScaledRating,
    double opponentScaledRd,
  ) {
    final g = _gFunction(opponentScaledRd * _scalingFactor);
    return 1.0 / (1.0 + math.exp(-g * (scaledRating - opponentScaledRating)));
  }

  double _computeVariance(
    double scaledRating,
    List<_OpponentData> opponentData,
  ) {
    final sum = opponentData.fold<double>(0, (sum, opponent) {
      final g = _gFunction(opponent.scaledRatingDeviation * _scalingFactor);
      final expectedScore = _eFunction(
        scaledRating,
        opponent.scaledRating,
        opponent.scaledRatingDeviation,
      );
      return sum + g * g * expectedScore * (1.0 - expectedScore);
    });
    return 1.0 / sum;
  }

  double _computeDelta(
    double scaledRating,
    List<_OpponentData> opponentData,
    double variance,
  ) {
    return variance * _computeDeltaSum(scaledRating, opponentData);
  }

  double _computeDeltaSum(
    double scaledRating,
    List<_OpponentData> opponentData,
  ) {
    return opponentData.fold<double>(0, (sum, opponent) {
      final g = _gFunction(opponent.scaledRatingDeviation * _scalingFactor);
      final expectedScore = _eFunction(
        scaledRating,
        opponent.scaledRating,
        opponent.scaledRatingDeviation,
      );
      return sum + g * (opponent.score - expectedScore);
    });
  }

  double _computeNewVolatility(
    double scaledRatingDeviation,
    double variance,
    double delta,
    double currentVolatility,
  ) {
    final a = math.log(currentVolatility * currentVolatility);

    double f(double x) {
      final eX = math.exp(x);
      final rdSquared = scaledRatingDeviation * scaledRatingDeviation;
      final deltaSquared = delta * delta;

      final numerator = eX * (deltaSquared - rdSquared - variance - eX);
      final denominator = 2.0 * math.pow(rdSquared + variance + eX, 2);
      final subtraction = (x - a) / (volatilityConstraint * volatilityConstraint);

      return numerator / denominator - subtraction;
    }

    double A = a;
    double B;

    if (delta * delta > scaledRatingDeviation * scaledRatingDeviation + variance) {
      B = math.log(
        delta * delta - scaledRatingDeviation * scaledRatingDeviation - variance,
      );
    } else {
      int k = 1;
      while (f(a - k * volatilityConstraint) < 0) {
        k++;
      }
      B = a - k * volatilityConstraint;
    }

    double fA = f(A);
    double fB = f(B);

    while ((B - A).abs() > convergenceTolerance) {
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
