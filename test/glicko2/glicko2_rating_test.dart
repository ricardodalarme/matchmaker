import 'package:matchmaker/matchmaker.dart';
import 'package:test/test.dart';

void main() {
  group('Glicko2Rating', () {
    test('creates rating with default values', () {
      const rating = Glicko2Rating();

      expect(rating.rating, equals(1500.0));
      expect(rating.rd, equals(350.0));
      expect(rating.volatility, equals(0.06));
    });

    test('creates rating with custom values', () {
      const rating = Glicko2Rating(
        rating: 1800,
        rd: 50,
        volatility: 0.05,
      );

      expect(rating.rating, equals(1800.0));
      expect(rating.rd, equals(50.0));
      expect(rating.volatility, equals(0.05));
    });

    test('calculates 95% confidence interval correctly', () {
      const rating = Glicko2Rating(rating: 1500, rd: 50);
      final interval = rating.getConfidenceInterval();

      // 95% CI = rating ± 1.96 * RD
      expect(interval.lower, closeTo(1402.0, 0.1));
      expect(interval.upper, closeTo(1598.0, 0.1));
    });

    test('copyWith creates new instance with updated values', () {
      const original = Glicko2Rating(rating: 1500, rd: 200, volatility: 0.06);
      final updated = original.copyWith(rating: 1550);

      expect(updated.rating, equals(1550.0));
      expect(updated.rd, equals(200.0));
      expect(updated.volatility, equals(0.06));
      expect(identical(original, updated), isFalse);
    });
  });
}
