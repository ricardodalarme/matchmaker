/// Base interface for all rating systems.
abstract interface class Rating {
  /// The player's skill rating value.
  ///
  /// Higher values indicate stronger players.
  double get rating;
}
