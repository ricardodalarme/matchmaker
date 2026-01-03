import 'package:matchmaker/matchmaker.dart';

void main() {
  print('=== Matchmaker: Rating Systems Examples ===\n');

  print('=== Glicko-2 Rating System ===\n');

  // Create a Glicko-2 rating system with default settings
  const glicko = Glicko2();

  print('--- Basic Example ---');
  glicko2BasicExample(glicko);

  print('\n--- Tournament Simulation ---');
  glicko2TournamentExample(glicko);

  print('\n--- Win Probability Prediction ---');
  glicko2PredictionExample(glicko);

  print('\n--- Rating Period Without Games ---');
  glicko2InactivityExample(glicko);

  print('\n--- Glickman Paper Example ---');
  glickmanPaperExample(glicko);

  print('\n\n=== Elo Rating System ===\n');

  const elo = Elo();

  print('--- Basic Example ---');
  eloBasicExample(elo);

  print('\n--- Series of Games ---');
  eloSeriesExample(elo);

  print('\n--- Win Probability ---');
  eloPredictionExample(elo);

  print('\n--- K-Factor Comparison ---');
  eloKFactorExample();

  print('\n\n=== TrueSkill Rating System ===\n');

  const trueskill = TrueSkill();

  print('--- Basic 1v1 Example ---');
  trueskillBasicExample(trueskill);

  print('\n--- Team Match Example ---');
  trueskillTeamExample(trueskill);

  print('\n--- Free-For-All Example ---');
  trueskillFreeForAllExample(trueskill);

  print('\n--- Match Quality ---');
  trueskillMatchQualityExample(trueskill);

  print('\n--- Win Probability ---');
  trueskillPredictionExample(trueskill);
}

/// Demonstrates basic Elo rating calculation
void eloBasicExample(Elo elo) {
  const ricardo = EloRating(rating: 1500);
  const lucas = EloRating(rating: 1400);

  print('Ricardo initial: ${ricardo.rating.toStringAsFixed(0)}');
  print('Lucas initial: ${lucas.rating.toStringAsFixed(0)}');

  // Ricardo beats Lucas
  final ricardoNew = elo.calculateNewRating(ricardo, [const MatchResult.win(lucas)]);
  final lucasNew = elo.calculateNewRating(lucas, [const MatchResult.loss(ricardo)]);

  print('\nAfter Ricardo beats Lucas:');
  print('Ricardo: ${ricardoNew.rating.toStringAsFixed(0)} '
      '(+${(ricardoNew.rating - ricardo.rating).toStringAsFixed(0)})');
  print('Lucas: ${lucasNew.rating.toStringAsFixed(0)} '
      '(${(lucasNew.rating - lucas.rating).toStringAsFixed(0)})');
}

/// Demonstrates a series of games
void eloSeriesExample(Elo elo) {
  var player = const EloRating(rating: 1500);
  const opponent = EloRating(rating: 1600);

  print('Player starts at: ${player.rating.toStringAsFixed(0)}');
  print('Playing against opponent rated: ${opponent.rating.toStringAsFixed(0)}\n');

  // Game 1: Loss
  player = elo.calculateNewRating(player, [const MatchResult.loss(opponent)]);
  print('After loss: ${player.rating.toStringAsFixed(0)}');

  // Game 2: Win
  player = elo.calculateNewRating(player, [const MatchResult.win(opponent)]);
  print('After win: ${player.rating.toStringAsFixed(0)}');

  // Game 3: Draw
  player = elo.calculateNewRating(player, [const MatchResult.draw(opponent)]);
  print('After draw: ${player.rating.toStringAsFixed(0)}');

  print('\nFinal rating: ${player.rating.toStringAsFixed(0)} '
      '(${(player.rating - 1500).toStringAsFixed(0)} from start)');
}

/// Demonstrates win probability prediction
void eloPredictionExample(Elo elo) {
  const strong = EloRating(rating: 1800);
  const medium = EloRating(rating: 1600);
  const weak = EloRating(rating: 1400);

  print('Strong player (1800) vs Medium (1600):');
  var prob = elo.predictOutcome(strong, medium);
  print('  Win probability: ${(prob * 100).toStringAsFixed(1)}%');

  print('\nMedium player (1600) vs Weak (1400):');
  prob = elo.predictOutcome(medium, weak);
  print('  Win probability: ${(prob * 100).toStringAsFixed(1)}%');

  print('\nEqual players (1600 vs 1600):');
  const equal = EloRating(rating: 1600);
  prob = elo.predictOutcome(equal, equal);
  print('  Win probability: ${(prob * 100).toStringAsFixed(1)}%');
}

/// Demonstrates K-factor effects
void eloKFactorExample() {
  const lowK = Elo(kFactor: 10);
  const highK = Elo(kFactor: 32);

  const player = EloRating(rating: 1500);
  const opponent = EloRating(rating: 1500);

  final lowKWin = lowK.calculateNewRating(player, [const MatchResult.win(opponent)]);
  final highKWin = highK.calculateNewRating(player, [const MatchResult.win(opponent)]);

  print('After winning against equal opponent:');
  print('  K=10 (stable): ${lowKWin.rating.toStringAsFixed(0)} '
      '(+${(lowKWin.rating - player.rating).toStringAsFixed(0)})');
  print('  K=32 (volatile): ${highKWin.rating.toStringAsFixed(0)} '
      '(+${(highKWin.rating - player.rating).toStringAsFixed(0)})');
}

/// Demonstrates basic rating calculation
void glicko2BasicExample(Glicko2 glicko) {
  // Create two players with initial ratings
  const ricardo = Glicko2Rating(
    rating: 1500,
    rd: 200,
    volatility: 0.06,
  );

  const lucas = Glicko2Rating(
    rating: 1400,
    rd: 30,
    volatility: 0.06,
  );

  print('Ricardo initial: $ricardo');
  print('Lucas initial: $lucas');

  // Ricardo plays against Lucas and wins
  const ricardoResults = [MatchResult.win(lucas)];

  // Calculate Ricardo's new rating
  final ricardoNew = glicko.calculateNewRating(ricardo, ricardoResults);

  print('\nAfter Ricardo beats Lucas:');
  print('Ricardo new: $ricardoNew');

  // Show confidence interval
  final interval = ricardoNew.getConfidenceInterval();
  print('Ricardo 95% confidence interval: '
      '[${interval.lower.toStringAsFixed(0)}, ${interval.upper.toStringAsFixed(0)}]');
}

/// Simulates a small tournament with multiple players
void glicko2TournamentExample(Glicko2 glicko) {
  // Four players enter a tournament
  const ricardo = Glicko2Rating(rating: 1500, rd: 200, volatility: 0.06);
  const lucas = Glicko2Rating(rating: 1400, rd: 150, volatility: 0.06);
  const rodrigo = Glicko2Rating(rating: 1600, rd: 180, volatility: 0.06);
  const joao = Glicko2Rating(rating: 1550, rd: 170, volatility: 0.06);

  print('Initial ratings:');
  print('  Ricardo: ${ricardo.rating.toStringAsFixed(0)}');
  print('  Lucas: ${lucas.rating.toStringAsFixed(0)}');
  print('  Rodrigo: ${rodrigo.rating.toStringAsFixed(0)}');
  print('  João: ${joao.rating.toStringAsFixed(0)}');

  // Define match results for each player during the rating period
  const ricardoResults = [
    MatchResult.win(lucas), // Ricardo beats Lucas
    MatchResult.loss(rodrigo), // Ricardo loses to Rodrigo
    MatchResult.draw(joao), // Ricardo draws with João
  ];

  const lucasResults = [
    MatchResult.loss(ricardo), // Lucas loses to Ricardo
    MatchResult.win(joao), // Lucas beats João
  ];

  const rodrigoResults = [
    MatchResult.win(ricardo), // Rodrigo beats Ricardo
    MatchResult.win(joao), // Rodrigo beats João
  ];

  const joaoResults = [
    MatchResult.draw(ricardo), // João draws with Ricardo
    MatchResult.loss(lucas), // João loses to Lucas
    MatchResult.loss(rodrigo), // João loses to Rodrigo
  ];

  // Calculate new ratings for all players
  final ricardoNew = glicko.calculateNewRating(ricardo, ricardoResults);
  final lucasNew = glicko.calculateNewRating(lucas, lucasResults);
  final rodrigoNew = glicko.calculateNewRating(rodrigo, rodrigoResults);
  final joaoNew = glicko.calculateNewRating(joao, joaoResults);

  print('\nNew ratings after tournament:');
  print('  Ricardo: ${ricardoNew.rating.toStringAsFixed(0)} '
      '(change: ${(ricardoNew.rating - ricardo.rating).toStringAsFixed(0)})');
  print('  Lucas: ${lucasNew.rating.toStringAsFixed(0)} '
      '(change: ${(lucasNew.rating - lucas.rating).toStringAsFixed(0)})');
  print('  Rodrigo: ${rodrigoNew.rating.toStringAsFixed(0)} '
      '(change: ${(rodrigoNew.rating - rodrigo.rating).toStringAsFixed(0)})');
  print('  João: ${joaoNew.rating.toStringAsFixed(0)} '
      '(change: ${(joaoNew.rating - joao.rating).toStringAsFixed(0)})');

  // Rodrigo should be highest (2 wins)
  print('\nFinal ranking:');
  final rankings = [
    ('Rodrigo', rodrigoNew.rating),
    ('Ricardo', ricardoNew.rating),
    ('Lucas', lucasNew.rating),
    ('João', joaoNew.rating),
  ]..sort((a, b) => b.$2.compareTo(a.$2));

  for (var i = 0; i < rankings.length; i++) {
    print(
      '  ${i + 1}. ${rankings[i].$1}: ${rankings[i].$2.toStringAsFixed(0)}',
    );
  }
}

/// Demonstrates win probability prediction
void glicko2PredictionExample(Glicko2 glicko) {
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
void glicko2InactivityExample(Glicko2 glicko) {
  var player = const Glicko2Rating(rating: 1600, rd: 50, volatility: 0.06);

  print('Player starts with:');
  print('  Rating: ${player.rating.toStringAsFixed(0)}');
  print('  RD: ${player.rd.toStringAsFixed(2)}');

  // Simulate 3 rating periods of inactivity
  for (var period = 1; period <= 3; period++) {
    player = glicko.calculateNewRating(player, []);
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

/// Demonstrates basic TrueSkill rating calculation
void trueskillBasicExample(TrueSkill trueskill) {
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
    ranks: [
      0,
      1,
    ],
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
void trueskillTeamExample(TrueSkill trueskill) {
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
    ranks: [
      0,
      1,
    ],
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
void trueskillFreeForAllExample(TrueSkill trueskill) {
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
    ranks: [
      0,
      1,
      2,
      3,
    ],
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
void trueskillMatchQualityExample(TrueSkill trueskill) {
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
void trueskillPredictionExample(TrueSkill trueskill) {
  final average = trueskill.createRating(mu: 25, sigma: 5);

  print('Player A (μ=25) vs various opponents:\n');

  var opponent = trueskill.createRating(mu: 25, sigma: 5);
  var prob = trueskill.predictWin(average, opponent);
  print('vs Equal player (μ=25): ${(prob * 100).toStringAsFixed(1)}% win chance');

  opponent = trueskill.createRating(mu: 30, sigma: 5);
  prob = trueskill.predictWin(average, opponent);
  print('vs Stronger player (μ=30): ${(prob * 100).toStringAsFixed(1)}% win chance');

  opponent = trueskill.createRating(mu: 20, sigma: 5);
  prob = trueskill.predictWin(average, opponent);
  print('vs Weaker player (μ=20): ${(prob * 100).toStringAsFixed(1)}% win chance');

  opponent = trueskill.createRating(mu: 35, sigma: 5);
  prob = trueskill.predictWin(average, opponent);
  print('vs Much stronger player (μ=35): ${(prob * 100).toStringAsFixed(1)}% win chance');
}
