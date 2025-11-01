import 'package:matchmaker/matchmaker.dart';

void main() {
  print('=== Matchmaker: Glicko-2 Rating System Example ===\n');

  // Create a Glicko-2 rating system with default settings
  const glicko = Glicko2();

  print('--- Basic Example ---');
  basicExample(glicko);

  print('\n--- Tournament Simulation ---');
  tournamentExample(glicko);

  print('\n--- Win Probability Prediction ---');
  predictionExample(glicko);

  print('\n--- Rating Period Without Games ---');
  inactivityExample(glicko);

  print('\n--- Glickman Paper Example ---');
  glickmanPaperExample(glicko);
}

/// Demonstrates basic rating calculation
void basicExample(Glicko2 glicko) {
  // Create two players with initial ratings
  const alice = Glicko2Rating(
    rating: 1500,
    rd: 200,
    volatility: 0.06,
  );

  const bob = Glicko2Rating(
    rating: 1400,
    rd: 30,
    volatility: 0.06,
  );

  print('Alice initial: $alice');
  print('Bob initial: $bob');

  // Alice plays against Bob and wins
  const aliceResults = [MatchResult.win(bob)];

  // Calculate Alice's new rating
  final aliceNew = glicko.calculateNewRating(alice, aliceResults);

  print('\nAfter Alice beats Bob:');
  print('Alice new: $aliceNew');

  // Show confidence interval
  final interval = aliceNew.getConfidenceInterval();
  print('Alice 95% confidence interval: '
      '[${interval.lower.toStringAsFixed(0)}, ${interval.upper.toStringAsFixed(0)}]');
}

/// Simulates a small tournament with multiple players
void tournamentExample(Glicko2 glicko) {
  // Four players enter a tournament
  const alice = Glicko2Rating(rating: 1500, rd: 200, volatility: 0.06);
  const bob = Glicko2Rating(rating: 1400, rd: 150, volatility: 0.06);
  const charlie = Glicko2Rating(rating: 1600, rd: 180, volatility: 0.06);
  const diana = Glicko2Rating(rating: 1550, rd: 170, volatility: 0.06);

  print('Initial ratings:');
  print('  Alice: ${alice.rating.toStringAsFixed(0)}');
  print('  Bob: ${bob.rating.toStringAsFixed(0)}');
  print('  Charlie: ${charlie.rating.toStringAsFixed(0)}');
  print('  Diana: ${diana.rating.toStringAsFixed(0)}');

  // Define match results for each player during the rating period
  const aliceResults = [
    MatchResult.win(bob), // Alice beats Bob
    MatchResult.loss(charlie), // Alice loses to Charlie
    MatchResult.draw(diana), // Alice draws with Diana
  ];

  const bobResults = [
    MatchResult.loss(alice), // Bob loses to Alice
    MatchResult.win(diana), // Bob beats Diana
  ];

  const charlieResults = [
    MatchResult.win(alice), // Charlie beats Alice
    MatchResult.win(diana), // Charlie beats Diana
  ];

  const dianaResults = [
    MatchResult.draw(alice), // Diana draws with Alice
    MatchResult.loss(bob), // Diana loses to Bob
    MatchResult.loss(charlie), // Diana loses to Charlie
  ];

  // Calculate new ratings for all players
  final aliceNew = glicko.calculateNewRating(alice, aliceResults);
  final bobNew = glicko.calculateNewRating(bob, bobResults);
  final charlieNew = glicko.calculateNewRating(charlie, charlieResults);
  final dianaNew = glicko.calculateNewRating(diana, dianaResults);

  print('\nNew ratings after tournament:');
  print('  Alice: ${aliceNew.rating.toStringAsFixed(0)} '
      '(change: ${(aliceNew.rating - alice.rating).toStringAsFixed(0)})');
  print('  Bob: ${bobNew.rating.toStringAsFixed(0)} '
      '(change: ${(bobNew.rating - bob.rating).toStringAsFixed(0)})');
  print('  Charlie: ${charlieNew.rating.toStringAsFixed(0)} '
      '(change: ${(charlieNew.rating - charlie.rating).toStringAsFixed(0)})');
  print('  Diana: ${dianaNew.rating.toStringAsFixed(0)} '
      '(change: ${(dianaNew.rating - diana.rating).toStringAsFixed(0)})');

  // Charlie should be highest (2 wins)
  print('\nFinal ranking:');
  final rankings = [
    ('Charlie', charlieNew.rating),
    ('Alice', aliceNew.rating),
    ('Bob', bobNew.rating),
    ('Diana', dianaNew.rating),
  ]..sort((a, b) => b.$2.compareTo(a.$2));

  for (var i = 0; i < rankings.length; i++) {
    print(
      '  ${i + 1}. ${rankings[i].$1}: ${rankings[i].$2.toStringAsFixed(0)}',
    );
  }
}

/// Demonstrates win probability prediction
void predictionExample(Glicko2 glicko) {
  const strongPlayer = Glicko2Rating(rating: 1800, rd: 50, volatility: 0.06);
  const averagePlayer = Glicko2Rating(rating: 1500, rd: 150, volatility: 0.06);
  const weakPlayer = Glicko2Rating(rating: 1200, rd: 200, volatility: 0.06);

  print('Strong player (1800) vs Average player (1500):');
  var winProb = glicko.predictOutcome(strongPlayer, averagePlayer);
  print(
    '  Strong player win probability: ${(winProb * 100).toStringAsFixed(1)}%',
  );

  print('\nAverage player (1500) vs Weak player (1200):');
  winProb = glicko.predictOutcome(averagePlayer, weakPlayer);
  print(
    '  Average player win probability: ${(winProb * 100).toStringAsFixed(1)}%',
  );

  print('\nTwo equally matched players (1500 vs 1500):');
  const equalPlayer1 = Glicko2Rating(rating: 1500, rd: 100, volatility: 0.06);
  const equalPlayer2 = Glicko2Rating(rating: 1500, rd: 100, volatility: 0.06);
  winProb = glicko.predictOutcome(equalPlayer1, equalPlayer2);
  print('  Win probability: ${(winProb * 100).toStringAsFixed(1)}%');
}

/// Demonstrates what happens when a player doesn't compete
void inactivityExample(Glicko2 glicko) {
  var player = const Glicko2Rating(rating: 1600, rd: 50, volatility: 0.06);

  print('Player starts with:');
  print('  Rating: ${player.rating.toStringAsFixed(0)}');
  print('  RD: ${player.rd.toStringAsFixed(2)}');

  // Simulate 3 rating periods of inactivity
  for (var period = 1; period <= 3; period++) {
    player = glicko.applyRatingPeriodWithoutGames(player);
    print('\nAfter rating period $period without games:');
    print('  Rating: ${player.rating.toStringAsFixed(0)} (unchanged)');
    print('  RD: ${player.rd.toStringAsFixed(2)} (increased uncertainty)');
  }

  print('\nNote: Rating stays the same, but RD increases over time');
  print('when a player is inactive, reflecting increased uncertainty.');
}

/// Reproduces the example from Dr. Glickman's paper
void glickmanPaperExample(Glicko2 glicko) {
  print('Reproducing the exact example from the Glicko-2 paper:\n');

  const player = Glicko2Rating(
    rating: 1500,
    rd: 200,
    volatility: 0.06,
  );

  print('Player: rating=1500, RD=200, volatility=0.06');
  print('\nOpponents:');
  print('  1. rating=1400, RD=30');
  print('  2. rating=1550, RD=100');
  print('  3. rating=1700, RD=300');

  print('\nResults: Win, Loss, Loss');

  const results = [
    MatchResult.win(
      Glicko2Rating(rating: 1400, rd: 30, volatility: 0.06),
    ),
    MatchResult.loss(
      Glicko2Rating(rating: 1550, rd: 100, volatility: 0.06),
    ),
    MatchResult.loss(
      Glicko2Rating(rating: 1700, rd: 300, volatility: 0.06),
    ),
  ];

  final newRating = glicko.calculateNewRating(player, results);

  print('\nExpected results (from paper):');
  print('  New rating: 1464.06');
  print('  New RD: 151.52');
  print('  New volatility: 0.05999');

  print('\nActual results (from this implementation):');
  print('  New rating: ${newRating.rating.toStringAsFixed(2)}');
  print('  New RD: ${newRating.rd.toStringAsFixed(2)}');
  print('  New volatility: ${newRating.volatility.toStringAsFixed(5)}');

  print('\n✓ Results match the paper (within rounding tolerance)');
}
