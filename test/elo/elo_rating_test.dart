import 'package:matchmaker/matchmaker.dart';
import 'package:test/test.dart';

void main() {
  group('EloRating', () {
    test('creates rating with value', () {
      const rating = EloRating(rating: 1500);

      expect(rating.rating, equals(1500));
    });

    test('toString returns formatted string', () {
      const rating = EloRating(rating: 1500.7);

      expect(rating.toString(), equals('EloRating(rating: 1501)'));
    });

    test('equality works correctly', () {
      const rating1 = EloRating(rating: 1500);
      const rating2 = EloRating(rating: 1500);
      const rating3 = EloRating(rating: 1600);

      expect(rating1, equals(rating2));
      expect(rating1, isNot(equals(rating3)));
    });

    test('hashCode works correctly', () {
      const rating1 = EloRating(rating: 1500);
      const rating2 = EloRating(rating: 1500);

      expect(rating1.hashCode, equals(rating2.hashCode));
    });
  });
}
