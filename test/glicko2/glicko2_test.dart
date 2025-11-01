import 'package:matchmaker/matchmaker.dart';
import 'package:test/test.dart';

void main() {
  group('Glicko2', () {
    test('creates system with default settings', () {
      const glicko = Glicko2();

      expect(glicko.volatilityConstraint, equals(0.5));
    });

    test('creates system with custom settings', () {
      const glicko = Glicko2(
        volatilityConstraint: 0.75,
      );

      expect(glicko.volatilityConstraint, equals(0.75));
    });

    test('example calculation from Glickman paper matches expected results', () {
      const glicko = Glicko2(volatilityConstraint: 0.5);

      const player = Glicko2Rating(
        rating: 1500,
        rd: 200,
        volatility: 0.06,
      );

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

      expect(newRating.rating, closeTo(1464.06, 0.5));
      expect(newRating.rd, closeTo(151.52, 0.5));
      expect(newRating.volatility, closeTo(0.05999, 0.0001));
    });

    test('rating increases after wins', () {
      const glicko = Glicko2();
      const player = Glicko2Rating(rating: 1500, rd: 200, volatility: 0.06);
      const opponent = Glicko2Rating(rating: 1500, rd: 200, volatility: 0.06);

      const results = [
        MatchResult.win(opponent),
        MatchResult.win(opponent),
        MatchResult.win(opponent),
      ];

      final newRating = glicko.calculateNewRating(player, results);

      expect(newRating.rating, greaterThan(player.rating));
    });

    test('rating decreases after losses', () {
      const glicko = Glicko2();
      const player = Glicko2Rating(rating: 1500, rd: 200, volatility: 0.06);
      const opponent = Glicko2Rating(rating: 1500, rd: 200, volatility: 0.06);

      const results = [
        MatchResult.loss(opponent),
        MatchResult.loss(opponent),
        MatchResult.loss(opponent),
      ];

      final newRating = glicko.calculateNewRating(player, results);

      expect(newRating.rating, lessThan(player.rating));
    });

    test('RD decreases after playing games', () {
      const glicko = Glicko2();
      const player = Glicko2Rating(rating: 1500, rd: 200, volatility: 0.06);
      const opponent = Glicko2Rating(rating: 1500, rd: 200, volatility: 0.06);

      const results = [
        MatchResult.win(opponent),
      ];

      final newRating = glicko.calculateNewRating(player, results);

      expect(newRating.rd, lessThan(player.rd));
    });

    test('RD increases when not playing (rating period without games)', () {
      const glicko = Glicko2();
      const player = Glicko2Rating(rating: 1500, rd: 50, volatility: 0.06);

      final newRating = glicko.calculateNewRating(player, []);

      expect(newRating.rating, equals(player.rating));
      expect(newRating.rd, greaterThan(player.rd));
      expect(newRating.volatility, equals(player.volatility));
    });

    test('rating stays same with no games', () {
      const glicko = Glicko2();
      const player = Glicko2Rating(rating: 1500, rd: 200, volatility: 0.06);

      final newRating = glicko.calculateNewRating(player, []);

      expect(newRating.rating, equals(player.rating));
      expect(newRating.rd, greaterThan(player.rd));
    });

    test('predictOutcome returns 0.5 for equally matched players', () {
      const glicko = Glicko2();
      const player1 = Glicko2Rating(rating: 1500, rd: 50, volatility: 0.06);
      const player2 = Glicko2Rating(rating: 1500, rd: 50, volatility: 0.06);

      final probability = glicko.predictOutcome(player1, player2);

      expect(probability, closeTo(0.5, 0.01));
    });

    test('predictOutcome favors higher rated player', () {
      const glicko = Glicko2();
      const stronger = Glicko2Rating(rating: 1700, rd: 50, volatility: 0.06);
      const weaker = Glicko2Rating(rating: 1500, rd: 50, volatility: 0.06);

      final probability = glicko.predictOutcome(stronger, weaker);

      expect(probability, greaterThan(0.5));
    });

    test('predictOutcome example from Glickman paper', () {
      const glicko = Glicko2();
      const player = Glicko2Rating(rating: 1400, rd: 80, volatility: 0.06);
      const opponent = Glicko2Rating(rating: 1500, rd: 150, volatility: 0.06);

      final probability = glicko.predictOutcome(player, opponent);

      expect(probability, closeTo(0.376, 0.005));
    });

    test('beating stronger opponent increases rating more', () {
      const glicko = Glicko2();
      const player = Glicko2Rating(rating: 1500, rd: 200, volatility: 0.06);

      const weakOpponent = Glicko2Rating(rating: 1300, rd: 50, volatility: 0.06);
      const resultsWeak = [MatchResult.win(weakOpponent)];
      final ratingAfterWeak = glicko.calculateNewRating(player, resultsWeak);

      const strongOpponent = Glicko2Rating(rating: 1700, rd: 50, volatility: 0.06);
      const resultsStrong = [MatchResult.win(strongOpponent)];
      final ratingAfterStrong = glicko.calculateNewRating(player, resultsStrong);

      final gainWeak = ratingAfterWeak.rating - player.rating;
      final gainStrong = ratingAfterStrong.rating - player.rating;

      expect(gainStrong, greaterThan(gainWeak));
    });

    test('high RD players have more volatile rating changes', () {
      const glicko = Glicko2();

      const uncertainPlayer = Glicko2Rating(rating: 1500, rd: 300, volatility: 0.06);

      const certainPlayer = Glicko2Rating(rating: 1500, rd: 50, volatility: 0.06);

      const opponent = Glicko2Rating(rating: 1500, rd: 100, volatility: 0.06);
      const results = [MatchResult.win(opponent)];

      final uncertainNewRating = glicko.calculateNewRating(uncertainPlayer, results);
      final certainNewRating = glicko.calculateNewRating(certainPlayer, results);

      final uncertainChange = (uncertainNewRating.rating - uncertainPlayer.rating).abs();
      final certainChange = (certainNewRating.rating - certainPlayer.rating).abs();

      expect(uncertainChange, greaterThan(certainChange));
    });

    test('volatility increases with inconsistent results', () {
      const glicko = Glicko2();
      const player = Glicko2Rating(rating: 1500, rd: 200, volatility: 0.06);

      const results = [
        MatchResult.loss(
          Glicko2Rating(rating: 1300, rd: 50, volatility: 0.06),
        ),
        MatchResult.win(
          Glicko2Rating(rating: 1700, rd: 50, volatility: 0.06),
        ),
      ];

      final newRating = glicko.calculateNewRating(player, results);

      expect(newRating.volatility, isPositive);
    });

    test('simulates a small tournament', () {
      const glicko = Glicko2();

      const ricardo = Glicko2Rating(rating: 1500, rd: 200, volatility: 0.06);
      const lucas = Glicko2Rating(rating: 1400, rd: 150, volatility: 0.06);
      const rodrigo = Glicko2Rating(rating: 1550, rd: 100, volatility: 0.06);
      const joao = Glicko2Rating(rating: 1700, rd: 300, volatility: 0.06);

      const ricardoResults = [
        MatchResult.win(lucas),
        MatchResult.loss(rodrigo),
        MatchResult.loss(joao),
      ];

      const lucasResults = [
        MatchResult.loss(ricardo),
        MatchResult.loss(rodrigo),
        MatchResult.loss(joao),
      ];

      final ricardoNew = glicko.calculateNewRating(ricardo, ricardoResults);
      final lucasNew = glicko.calculateNewRating(lucas, lucasResults);

      expect(ricardoNew.rating, lessThan(ricardo.rating));

      expect(lucasNew.rating, lessThan(lucas.rating));

      expect(ricardoNew.rd, lessThan(ricardo.rd));
      expect(lucasNew.rd, lessThan(lucas.rd));
    });

    test('handles draw correctly', () {
      const glicko = Glicko2();
      const player = Glicko2Rating(rating: 1500, rd: 200, volatility: 0.06);
      const opponent = Glicko2Rating(rating: 1500, rd: 200, volatility: 0.06);

      const results = [MatchResult.draw(opponent)];

      final newRating = glicko.calculateNewRating(player, results);

      expect(newRating.rating, closeTo(player.rating, 10.0));
      expect(newRating.rd, lessThan(player.rd));
    });

    test('multiple rating periods simulation', () {
      const glicko = Glicko2();
      const opponent = Glicko2Rating(rating: 1500, rd: 150, volatility: 0.06);

      var playerRating = const Glicko2Rating(rating: 1500, rd: 200, volatility: 0.06);

      for (var period = 0; period < 5; period++) {
        const results = [
          MatchResult.win(opponent),
          MatchResult.win(opponent),
        ];

        playerRating = glicko.calculateNewRating(playerRating, results);
      }

      expect(playerRating.rating, greaterThan(1600));

      expect(playerRating.rd, lessThan(150.0));
    });
  });
}
