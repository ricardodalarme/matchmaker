import 'dart:math' as math;

import 'package:matchmaker/src/glicko2/glicko2.dart';

class Glicko2Math {
  Glicko2Math._();

  /// The g function from the Glicko-2 algorithm.
  ///
  /// Reduces the impact of games against opponents with high rating deviation.
  /// This function accounts for the uncertainty in an opponent's rating.
  static double g(double rd) {
    final phi = rd / Glicko2.scalingFactor;
    return 1.0 / math.sqrt(1.0 + 3.0 * phi * phi / (math.pi * math.pi));
  }

  /// The E function - calculates the expected score against an opponent.
  ///
  /// Returns a value between 0 and 1 representing the probability of winning.
  /// - [mu]: Player's rating in Glicko-2 scale
  /// - [muJ]: Opponent's rating in Glicko-2 scale
  /// - [phiJ]: Opponent's rating deviation in Glicko-2 scale
  static double e(double mu, double muJ, double phiJ) {
    final gValue = g(phiJ * Glicko2.scalingFactor);
    return 1.0 / (1.0 + math.exp(-gValue * (mu - muJ)));
  }
}
