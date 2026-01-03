import 'package:matchmaker/matchmaker.dart';

void main() {
  print('=== TrueSkill Rating System Examples ===\n');

  const trueskill = TrueSkill();

  print('--- Basic 1v1 Example ---');
  basicExample(trueskill);

  print('\n--- Team Match Example ---');
  teamExample(trueskill);

  print('\n--- Free-For-All Example ---');
  freeForAllExample(trueskill);

  print('\n--- Match Quality ---');
  matchQualityExample(trueskill);

  print('\n--- Win Probability ---');
  predictionExample(trueskill);
}

/// Demonstrates basic TrueSkill rating calculation
void basicExample(TrueSkill trueskill) {
  final alice = trueskill.createRating();
  final bob = trueskill.createRating();

  print('Alice initial: $alice');
  print('Bob initial: $bob');

  // Alice beats Bob
  final results = trueskill.rate(
    [
      [alice],
      [bob],
    ],
    ranks: [0, 1],
  );

  final newAlice = results[0][0];
  final newBob = results[1][0];

  print('\nAfter Alice beats Bob:');
  print('Alice: $newAlice');
  print('  Change: μ ${(newAlice.mu - alice.mu).toStringAsFixed(2)}, '
      'σ ${(newAlice.sigma - alice.sigma).toStringAsFixed(2)}');
  print('Bob: $newBob');
  print('  Change: μ ${(newBob.mu - bob.mu).toStringAsFixed(2)}, '
      'σ ${(newBob.sigma - bob.sigma).toStringAsFixed(2)}');
}

/// Demonstrates team match in TrueSkill
void teamExample(TrueSkill trueskill) {
  final alice = trueskill.createRating();
  final bob = trueskill.createRating();
  final carol = trueskill.createRating();
  final dave = trueskill.createRating();

  print('Team A: Alice (${alice.conservativeRating.toStringAsFixed(1)}), '
      'Bob (${bob.conservativeRating.toStringAsFixed(1)})');
  print('Team B: Carol (${carol.conservativeRating.toStringAsFixed(1)}), '
      'Dave (${dave.conservativeRating.toStringAsFixed(1)})');

  // Team A wins
  final results = trueskill.rate(
    [
      [alice, bob],
      [carol, dave],
    ],
    ranks: [0, 1],
  );

  print('\nAfter Team A beats Team B:');
  final aliceChange = results[0][0].mu - alice.mu;
  final bobChange = results[0][1].mu - bob.mu;
  final carolChange = results[1][0].mu - carol.mu;
  final daveChange = results[1][1].mu - dave.mu;

  print('Alice: ${results[0][0].conservativeRating.toStringAsFixed(1)} '
      '(${aliceChange >= 0 ? '+' : ''}${aliceChange.toStringAsFixed(2)})');
  print('Bob: ${results[0][1].conservativeRating.toStringAsFixed(1)} '
      '(${bobChange >= 0 ? '+' : ''}${bobChange.toStringAsFixed(2)})');
  print('Carol: ${results[1][0].conservativeRating.toStringAsFixed(1)} '
      '(${carolChange >= 0 ? '+' : ''}${carolChange.toStringAsFixed(2)})');
  print('Dave: ${results[1][1].conservativeRating.toStringAsFixed(1)} '
      '(${daveChange >= 0 ? '+' : ''}${daveChange.toStringAsFixed(2)})');
}

/// Demonstrates free-for-all match
void freeForAllExample(TrueSkill trueskill) {
  final p1 = trueskill.createRating();
  final p2 = trueskill.createRating();
  final p3 = trueskill.createRating();
  final p4 = trueskill.createRating();

  print('Starting ratings (all equal):');
  print('  P1, P2, P3, P4: ${p1.conservativeRating.toStringAsFixed(1)}');

  // P1 wins, P2 second, P3 third, P4 last
  final results = trueskill.rate(
    [
      [p1],
      [p2],
      [p3],
      [p4],
    ],
    ranks: [0, 1, 2, 3],
  );

  print('\nAfter P1 wins, P2 second, P3 third, P4 last:');
  final p1Change = results[0][0].mu - p1.mu;
  final p2Change = results[1][0].mu - p2.mu;
  final p3Change = results[2][0].mu - p3.mu;
  final p4Change = results[3][0].mu - p4.mu;

  print('  P1 (1st): ${results[0][0].conservativeRating.toStringAsFixed(1)} '
      '(${p1Change >= 0 ? '+' : ''}${p1Change.toStringAsFixed(2)})');
  print('  P2 (2nd): ${results[1][0].conservativeRating.toStringAsFixed(1)} '
      '(${p2Change >= 0 ? '+' : ''}${p2Change.toStringAsFixed(2)})');
  print('  P3 (3rd): ${results[2][0].conservativeRating.toStringAsFixed(1)} '
      '(${p3Change >= 0 ? '+' : ''}${p3Change.toStringAsFixed(2)})');
  print('  P4 (4th): ${results[3][0].conservativeRating.toStringAsFixed(1)} '
      '(${p4Change >= 0 ? '+' : ''}${p4Change.toStringAsFixed(2)})');
}

/// Demonstrates match quality calculation
void matchQualityExample(TrueSkill trueskill) {
  print('Match quality helps determine if a match is fair:\n');

  // Equal skill players
  final alice = trueskill.createRating();
  final bob = trueskill.createRating();

  var quality = trueskill.quality([
    [alice],
    [bob],
  ]);
  print('Equal players (μ=25 vs μ=25):');
  print('  Quality: ${(quality * 100).toStringAsFixed(1)}%');

  // Moderately mismatched
  final skilled = trueskill.createRating(mu: 30, sigma: 5);
  final average = trueskill.createRating(mu: 25, sigma: 5);

  quality = trueskill.quality([
    [skilled],
    [average],
  ]);
  print('\nModerately mismatched (μ=30 vs μ=25):');
  print('  Quality: ${(quality * 100).toStringAsFixed(1)}%');

  // Highly mismatched
  final expert = trueskill.createRating(mu: 40, sigma: 3);
  final beginner = trueskill.createRating(mu: 15, sigma: 5);

  quality = trueskill.quality([
    [expert],
    [beginner],
  ]);
  print('\nHighly mismatched (μ=40 vs μ=15):');
  print('  Quality: ${(quality * 100).toStringAsFixed(1)}%');

  print('\nNote: Quality > 50% indicates a fair match');
}

/// Demonstrates win probability prediction
void predictionExample(TrueSkill trueskill) {
  final average = trueskill.createRating(mu: 25, sigma: 5);

  print('Player A (μ=25) vs various opponents:\n');

  var opponent = trueskill.createRating(mu: 25, sigma: 5);
  var prob = trueskill.predictWin(average, opponent);
  print(
    'vs Equal player (μ=25): ${(prob * 100).toStringAsFixed(1)}% win chance',
  );

  opponent = trueskill.createRating(mu: 30, sigma: 5);
  prob = trueskill.predictWin(average, opponent);
  print(
    'vs Stronger player (μ=30): ${(prob * 100).toStringAsFixed(1)}% win chance',
  );

  opponent = trueskill.createRating(mu: 20, sigma: 5);
  prob = trueskill.predictWin(average, opponent);
  print(
    'vs Weaker player (μ=20): ${(prob * 100).toStringAsFixed(1)}% win chance',
  );

  opponent = trueskill.createRating(mu: 35, sigma: 5);
  prob = trueskill.predictWin(average, opponent);
  print(
    'vs Much stronger player (μ=35): '
    '${(prob * 100).toStringAsFixed(1)}% win chance',
  );
}
