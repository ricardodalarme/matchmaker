import 'package:matchmaker/src/rating.dart';

/// Represents an Elo rating for a player.
///
/// The Elo rating system uses a single number to represent skill level.
/// A higher rating indicates a stronger player.
class EloRating implements Rating {
  /// Creates an Elo rating.
  ///
  /// [rating] is the player's skill level (typically starts around 1500).
  const EloRating({required this.rating});

  /// The player's rating value.
  ///
  /// Higher values indicate stronger players. The default starting rating
  /// is typically 1500, with most players falling between 1000 and 2000.
  /// Strong club players are around 2000, masters around 2200, and
  /// grandmasters 2500+.
  @override
  final double rating;

  @override
  String toString() => 'EloRating(rating: ${rating.toStringAsFixed(0)})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EloRating && runtimeType == other.runtimeType && rating == other.rating;

  @override
  int get hashCode => rating.hashCode;
}
