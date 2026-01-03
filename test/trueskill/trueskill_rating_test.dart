import 'package:matchmaker/matchmaker.dart';
import 'package:test/test.dart';

void main() {
  group('TrueSkillRating', () {
    test('creates rating with default values', () {
      const rating = TrueSkillRating(mu: 25, sigma: 8.333);

      expect(rating.mu, equals(25.0));
      expect(rating.sigma, equals(8.333));
      expect(rating.rating, equals(25.0));
    });

    test('calculates conservative rating correctly', () {
      const rating = TrueSkillRating(mu: 25, sigma: 8.333);

      // Conservative rating = mu - 3*sigma = 25 - 3*8.333 ≈ 0
      expect(rating.conservativeRating, closeTo(0.001, 0.1));
    });

    test('calculates exposure correctly', () {
      const rating = TrueSkillRating(mu: 30, sigma: 5);

      expect(rating.exposure(), equals(30.0 - 3 * 5.0)); // Default k=3
      expect(rating.exposure(2), equals(30.0 - 2 * 5.0)); // Custom k=2
      expect(rating.exposure(1), equals(30.0 - 1 * 5.0)); // Custom k=1
    });

    test('equality works correctly', () {
      const rating1 = TrueSkillRating(mu: 25, sigma: 8.333);
      const rating2 = TrueSkillRating(mu: 25, sigma: 8.333);
      const rating3 = TrueSkillRating(mu: 30, sigma: 5);

      expect(rating1, equals(rating2));
      expect(rating1, isNot(equals(rating3)));
    });

    test('toString formats correctly', () {
      const rating = TrueSkillRating(mu: 25.5, sigma: 8.333);

      expect(rating.toString(), contains('25.50'));
      expect(rating.toString(), contains('8.33'));
    });

    test('new player has conservative rating of ~0', () {
      const newPlayer = TrueSkillRating(mu: 25, sigma: 8.333333333333334);

      expect(newPlayer.conservativeRating, closeTo(0.0, 0.01));
    });

    test('experienced player has higher conservative rating', () {
      const experienced = TrueSkillRating(mu: 30, sigma: 2);

      // Conservative rating = 30 - 3*2 = 24
      expect(experienced.conservativeRating, equals(24.0));
    });
  });
}
