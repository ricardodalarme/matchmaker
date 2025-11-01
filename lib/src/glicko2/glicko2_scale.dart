import 'package:matchmaker/src/glicko2/glicko2.dart';

extension Glicko2ScaleConversion on double {
  static const double glickoDefaultRating = 1500;

  double toGlicko2Scale() {
    return (this - glickoDefaultRating) / Glicko2.scalingFactor;
  }

  double fromGlicko2Scale() {
    return this * Glicko2.scalingFactor + glickoDefaultRating;
  }
}
