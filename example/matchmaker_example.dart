import 'elo_example.dart' as elo;
import 'glicko2_example.dart' as glicko2;
import 'trueskill_example.dart' as trueskill;

/// Runs all rating system examples.
///
/// You can also run each example individually:
/// - `dart run example/elo_example.dart`
/// - `dart run example/glicko2_example.dart`
/// - `dart run example/trueskill_example.dart`
void main() {
  print('=== Matchmaker: Rating Systems Examples ===\n');

  glicko2.main();
  elo.main();
  trueskill.main();
}
