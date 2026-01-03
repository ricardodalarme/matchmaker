import 'package:matchmaker/matchmaker.dart';

void main() {
  print('=== Elo Rating System Examples ===\n');

  const elo = Elo();

  print('--- Basic Example ---');
  basicExample(elo);

  print('\n--- Series of Games ---');
  seriesExample(elo);

  print('\n--- Win Probability ---');
  predictionExample(elo);

  print('\n--- K-Factor Comparison ---');
  kFactorExample();
}

/// Demonstrates basic Elo rating calculation
void basicExample(Elo elo) {
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
void seriesExample(Elo elo) {
  var player = const EloRating(rating: 1500);
  const opponent = EloRating(rating: 1600);

  print('Player starts at: ${player.rating.toStringAsFixed(0)}');
  print(
    'Playing against opponent rated: ${opponent.rating.toStringAsFixed(0)}\n',
  );

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
void predictionExample(Elo elo) {
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
void kFactorExample() {
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
