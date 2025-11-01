import 'package:matchmaker/src/glicko2/glicko2_rating.dart';

/// Represents the outcome of a match between two players.
///
/// A match result consists of:
/// - The opponent's rating
/// - The score (1.0 for win, 0.5 for draw, 0.0 for loss)
class MatchResult {
  /// Creates a match result.
  ///
  /// [opponent] is the opponent's rating.
  /// [score] is the outcome: 1.0 (win), 0.5 (draw), or 0.0 (loss).
  const MatchResult({
    required this.opponent,
    required this.score,
  }) : assert(score >= 0.0 && score <= 1.0, 'Score must be between 0 and 1');

  /// Creates a match result for a win.
  const MatchResult.win(Glicko2Rating opponent)
      : this(opponent: opponent, score: 1);

  /// Creates a match result for a draw.
  const MatchResult.draw(Glicko2Rating opponent)
      : this(opponent: opponent, score: 0.5);

  /// Creates a match result for a loss.
  const MatchResult.loss(Glicko2Rating opponent)
      : this(opponent: opponent, score: 0);

  /// The opponent's rating at the time of the match.
  final Glicko2Rating opponent;

  /// The match outcome from the perspective of the player.
  ///
  /// - 1.0 = win
  /// - 0.5 = draw
  /// - 0.0 = loss
  final double score;

  @override
  String toString() {
    final outcome = switch (score) {
      1.0 => 'Win',
      0.5 => 'Draw',
      0.0 => 'Loss',
      _ => 'Score: $score',
    };

    return 'MatchResult($outcome vs ${opponent.rating.toStringAsFixed(0)})';
  }
}
