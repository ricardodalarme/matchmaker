import 'package:matchmaker/matchmaker.dart';
import 'package:test/test.dart';

void main() {
  group('MatchResult', () {
    const opponent = Glicko2Rating();

    test('creates win result', () {
      const result = MatchResult.win(opponent);

      expect(result.score, equals(1.0));
      expect(result.opponent, equals(opponent));
    });

    test('creates draw result', () {
      const result = MatchResult.draw(opponent);

      expect(result.score, equals(0.5));
      expect(result.opponent, equals(opponent));
    });

    test('creates loss result', () {
      const result = MatchResult.loss(opponent);

      expect(result.score, equals(0.0));
      expect(result.opponent, equals(opponent));
    });
  });
}
