/// Represents a player's rating in the Glicko-2 system.
///
/// Each player has three values:
/// - [rating]: The player's skill rating (higher = better)
/// - [rd]: Rating deviation - uncertainty in the rating (lower = more certain)
/// - [volatility]: Expected fluctuation in the player's rating
class Glicko2Rating {
  /// Creates a new Glicko-2 rating.
  ///
  /// - [rating]: The player's skill rating (default: 1500)
  /// - [rd]: Rating deviation (default: 350)
  /// - [volatility]: Rating volatility (default: 0.06)
  const Glicko2Rating({
    this.rating = 1500.0,
    this.rd = 350.0,
    this.volatility = 0.06,
  });

  /// The player's skill rating.
  ///
  /// Higher ratings indicate stronger players.
  final double rating;

  /// Rating deviation - indicates the uncertainty of the rating.
  ///
  /// Lower values indicate more confidence in the rating's accuracy.
  /// The RD increases over time when not playing, and decreases with each game.
  final double rd;

  /// Volatility - indicates the degree of expected fluctuation in rating.
  ///
  /// High volatility indicates erratic performance, low volatility indicates
  /// consistent performance.
  final double volatility;

  /// Returns the 95% confidence interval for this rating.
  ///
  /// This represents the range where we are 95% confident the player's
  /// true skill lies. The interval is calculated as:
  /// (rating - 1.96*RD, rating + 1.96*RD)
  ///
  /// Returns a record with (lower, upper) bounds.
  ({double lower, double upper}) getConfidenceInterval() {
    final margin = 1.96 * rd;
    return (lower: rating - margin, upper: rating + margin);
  }

  /// Creates a copy of this rating with updated values.
  Glicko2Rating copyWith({
    double? rating,
    double? rd,
    double? volatility,
  }) {
    return Glicko2Rating(
      rating: rating ?? this.rating,
      rd: rd ?? this.rd,
      volatility: volatility ?? this.volatility,
    );
  }

  @override
  String toString() {
    return 'Glicko2Rating(rating: ${rating.toStringAsFixed(2)}, '
        'rd: ${rd.toStringAsFixed(2)}, '
        'volatility: ${volatility.toStringAsFixed(5)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Glicko2Rating &&
        other.rating == rating &&
        other.rd == rd &&
        other.volatility == volatility;
  }

  @override
  int get hashCode => Object.hash(rating, rd, volatility);
}
