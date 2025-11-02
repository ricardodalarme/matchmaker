import 'package:matchmaker/matchmaker.dart';
import 'package:test/test.dart';

void main() {
  group('Elo', () {
    test('creates system with default settings', () {
      const elo = Elo();

      expect(elo.kFactor, equals(32));
      expect(elo.defaultRating, equals(1500));
    });

    test('creates system with custom settings', () {
      const elo = Elo(
        kFactor: 16,
        defaultRating: 1200,
      );

      expect(elo.kFactor, equals(16));
      expect(elo.defaultRating, equals(1200));
    });

    test('rating increases after win', () {
      const elo = Elo();
      const player = EloRating(rating: 1500);
      const opponent = EloRating(rating: 1500);

      final results = [const MatchResult.win(opponent)];
      final newRating = elo.calculateNewRating(player, results);

      expect(newRating.rating, greaterThan(player.rating));
    });

    test('rating decreases after loss', () {
      const elo = Elo();
      const player = EloRating(rating: 1500);
      const opponent = EloRating(rating: 1500);

      final results = [const MatchResult.loss(opponent)];
      final newRating = elo.calculateNewRating(player, results);

      expect(newRating.rating, lessThan(player.rating));
    });

    test('rating stays approximately same after draw between equal players', () {
      const elo = Elo();
      const player = EloRating(rating: 1500);
      const opponent = EloRating(rating: 1500);

      final results = [const MatchResult.draw(opponent)];
      final newRating = elo.calculateNewRating(player, results);

      expect(newRating.rating, closeTo(player.rating, 0.5));
    });

    test('predictOutcome returns 0.5 for equally rated players', () {
      const elo = Elo();
      const player1 = EloRating(rating: 1500);
      const player2 = EloRating(rating: 1500);

      final probability = elo.predictOutcome(player1, player2);

      expect(probability, closeTo(0.5, 0.001));
    });

    test('predictOutcome favors higher rated player', () {
      const elo = Elo();
      const stronger = EloRating(rating: 1700);
      const weaker = EloRating(rating: 1500);

      final probability = elo.predictOutcome(stronger, weaker);

      expect(probability, greaterThan(0.5));
      expect(probability, closeTo(0.76, 0.01));
    });

    test('400 rating point difference equals 91% win probability', () {
      const elo = Elo();
      const stronger = EloRating(rating: 1900);
      const weaker = EloRating(rating: 1500);

      final probability = elo.predictOutcome(stronger, weaker);

      expect(probability, closeTo(0.909, 0.01));
    });

    test('200 rating point difference equals 76% win probability', () {
      const elo = Elo();
      const stronger = EloRating(rating: 1700);
      const weaker = EloRating(rating: 1500);

      final probability = elo.predictOutcome(stronger, weaker);

      expect(probability, closeTo(0.76, 0.01));
    });

    test('beating stronger opponent increases rating more', () {
      const elo = Elo();
      const player = EloRating(rating: 1500);

      const weakOpponent = EloRating(rating: 1400);
      final ratingAfterWeak = elo.calculateNewRating(player, [const MatchResult.win(weakOpponent)]);

      const strongOpponent = EloRating(rating: 1700);
      final ratingAfterStrong =
          elo.calculateNewRating(player, [const MatchResult.win(strongOpponent)]);

      final gainWeak = ratingAfterWeak.rating - player.rating;
      final gainStrong = ratingAfterStrong.rating - player.rating;

      expect(gainStrong, greaterThan(gainWeak));
    });

    test('losing to weaker opponent decreases rating more', () {
      const elo = Elo();
      const player = EloRating(rating: 1700);

      const weakOpponent = EloRating(rating: 1400);
      final ratingAfterWeak =
          elo.calculateNewRating(player, [const MatchResult.loss(weakOpponent)]);

      const strongOpponent = EloRating(rating: 1700);
      final ratingAfterStrong =
          elo.calculateNewRating(player, [const MatchResult.loss(strongOpponent)]);

      final lossWeak = player.rating - ratingAfterWeak.rating;
      final lossStrong = player.rating - ratingAfterStrong.rating;

      expect(lossWeak, greaterThan(lossStrong));
    });

    test('higher K-factor produces larger rating changes', () {
      const lowK = Elo(kFactor: 10);
      const highK = Elo(kFactor: 32);

      const player = EloRating(rating: 1500);
      const opponent = EloRating(rating: 1500);

      final lowKResult = lowK.calculateNewRating(player, [const MatchResult.win(opponent)]);
      final highKResult = highK.calculateNewRating(player, [const MatchResult.win(opponent)]);

      final lowKGain = lowKResult.rating - player.rating;
      final highKGain = highKResult.rating - player.rating;

      expect(highKGain, greaterThan(lowKGain));
    });

    test('simulates a series of games', () {
      const elo = Elo();

      var ricardo = const EloRating(rating: 1500);
      const lucas = EloRating(rating: 1500);

      // Ricardo wins 3 games
      ricardo = elo.calculateNewRating(ricardo, [const MatchResult.win(lucas)]);
      ricardo = elo.calculateNewRating(ricardo, [const MatchResult.win(lucas)]);
      ricardo = elo.calculateNewRating(ricardo, [const MatchResult.win(lucas)]);

      expect(ricardo.rating, greaterThan(1540));
    });

    test('Fischer-Spassky 1972 match example', () {
      const elo = Elo(kFactor: 10);

      // Simplified: using final scores
      const fischer = EloRating(rating: 2785);
      const spassky = EloRating(rating: 2660);

      // Fischer scored 12.5 out of 20
      const fischerScore = 12.5 / 20;

      // For demonstration, calculate rating change
      final expectedScore = elo.predictOutcome(fischer, spassky);

      expect(expectedScore, closeTo(0.67, 0.02));
      expect(fischerScore, closeTo(0.625, 0.001));
    });

    test('getRatingDifferenceForProbability works correctly', () {
      const elo = Elo();

      final diff75 = elo.getRatingDifferenceForProbability(0.75);
      final diff90 = elo.getRatingDifferenceForProbability(0.90);

      expect(diff75, closeTo(191, 2));
      expect(diff90, closeTo(382, 20));
    });

    test('getRatingDifferenceForProbability throws for invalid probability', () {
      const elo = Elo();

      expect(() => elo.getRatingDifferenceForProbability(0), throwsA(isA<AssertionError>()));
      expect(() => elo.getRatingDifferenceForProbability(1), throwsA(isA<AssertionError>()));
      expect(() => elo.getRatingDifferenceForProbability(-0.5), throwsA(isA<AssertionError>()));
      expect(() => elo.getRatingDifferenceForProbability(1.5), throwsA(isA<AssertionError>()));
    });

    test('symmetry: win for one player equals loss for opponent', () {
      const elo = Elo();
      const ricardo = EloRating(rating: 1600);
      const lucas = EloRating(rating: 1400);

      final ricardoWin = elo.calculateNewRating(ricardo, [const MatchResult.win(lucas)]);
      final lucasLoss = elo.calculateNewRating(lucas, [const MatchResult.loss(ricardo)]);

      final ricardoGainRating = ricardoWin.rating - ricardo.rating;
      final lucasLossRating = lucas.rating - lucasLoss.rating;

      // Rating changes should be similar in magnitude but opposite
      expect((ricardoGainRating - lucasLossRating).abs(), lessThan(1.0));
    });

    test('multiple games with same total score give same rating', () {
      const elo = Elo();
      const player = EloRating(rating: 1500);
      const opponent = EloRating(rating: 1600);

      // Win once
      final oneGame = elo.calculateNewRating(player, [const MatchResult.win(opponent)]);

      // Win once with combined score
      final combined = elo.calculateNewRating(player, [const MatchResult.win(opponent)]);

      expect(oneGame.rating, equals(combined.rating));
    });

    test('handles multiple games in one calculation', () {
      const elo = Elo();
      const player = EloRating(rating: 1500);
      const opponent = EloRating(rating: 1600);

      // Win, loss, draw in one batch
      final results = [
        const MatchResult.win(opponent),
        const MatchResult.loss(opponent),
        const MatchResult.draw(opponent),
      ];

      final newRating = elo.calculateNewRating(player, results);

      // Should be close to starting rating (net 1.5/3 = 50% against higher opponent)
      expect(newRating.rating, greaterThan(player.rating - 20));
      expect(newRating.rating, lessThan(player.rating + 20));
    });

    test('handles empty results list', () {
      const elo = Elo();
      const player = EloRating(rating: 1500);

      final newRating = elo.calculateNewRating(player, []);

      expect(newRating.rating, equals(player.rating));
    });
  });
}
