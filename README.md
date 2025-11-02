# Matchmaker

[![pub package](https://img.shields.io/pub/v/matchmaker.svg)](https://pub.dev/packages/matchmaker)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Skill rating and matchmaking algorithms for competitive games. Currently supports Glicko-2 and Elo.

## Supported Rating Systems

### Glicko-2

[Glicko-2](https://www.glicko.net/glicko/glicko2.pdf) is an improved version of the classic Elo rating system. While Elo just tracks a single number, Glicko-2 tracks three things:

- **Rating**: Your skill level (usually starts at 1500)
- **Rating Deviation (RD)**: How certain we are about your rating. New players have high RD, which drops as they play more
- **Volatility**: How consistent you are. Erratic players have high volatility

**Best for**: Games with varying player activity, 1v1 competitive games, any scenario where you need to track rating uncertainty.

### Elo

The classic rating system developed by Arpad Elo for chess. Simple and effective - just one number that goes up when you win and down when you lose. Rating differences directly translate to win probabilities using a logistic curve.

- Clean mathematical foundation (logistic function)
- No uncertainty tracking - just skill level
- Easy to understand and explain to players
- Battle-tested across decades of competitive chess

**Best for**: Simple 1v1 games, when you want something straightforward, or when rating updates need to be transparent to players.

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  matchmaker: ^0.1.0
```

## Usage

### Glicko-2

#### Quick Start

```dart
import 'package:matchmaker/matchmaker.dart';

void main() {
  const glicko = Glicko2();

  // New players start with default ratings
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

  // Ricardo plays against Lucas and wins
  final results = [MatchResult.win(lucas)];

  // Calculate Ricardo's new rating
  final newRating = glicko.calculateNewRating(ricardo, results);

  print('New rating: ${newRating.rating.toStringAsFixed(0)}');
  print('New RD: ${newRating.rd.toStringAsFixed(2)}');
}
```

#### Tournament with multiple matches

```dart
const glicko = Glicko2();

const ricardo = Glicko2Rating(rating: 1500, rd: 200, volatility: 0.06);
const lucas = Glicko2Rating(rating: 1400, rd: 150, volatility: 0.06);
const rodrigo = Glicko2Rating(rating: 1600, rd: 180, volatility: 0.06);

// Ricardo plays three games
final results = [
  MatchResult.win(lucas),
  MatchResult.loss(rodrigo),
  MatchResult.draw(rodrigo),
];

final newRating = glicko.calculateNewRating(ricardo, results);
```

#### Predict match outcomes

```dart
const strong = Glicko2Rating(rating: 1800, rd: 50, volatility: 0.06);
const weak = Glicko2Rating(rating: 1200, rd: 200, volatility: 0.06);

final winChance = glicko.predictOutcome(strong, weak);
print('Win probability: ${(winChance * 100).toStringAsFixed(1)}%');
```

#### Confidence intervals

```dart
const player = Glicko2Rating(rating: 1650, rd: 80, volatility: 0.06);
final interval = player.getConfidenceInterval();

print('95% confident true skill is between '
      '${interval.lower.toStringAsFixed(0)} and '
      '${interval.upper.toStringAsFixed(0)}');
```

#### Handle inactive players

When a player doesn't compete, their rating stays the same but uncertainty increases:

```dart
var player = const Glicko2Rating(rating: 1600, rd: 50, volatility: 0.06);

// No games this period
player = glicko.calculateNewRating(player, []);

print('Rating: ${player.rating}');   // Still 1600
print('RD: ${player.rd}');           // Increased
```

#### Configuration

Customize the Glicko-2 system if you want:

```dart
const glicko = Glicko2(
  volatilityConstraint: 0.5,  // How much volatility can change (0.3-1.2)
);
```

**volatilityConstraint**: Lower (0.3-0.6) for stable games, higher (0.8-1.2) for unpredictable ones. Default 0.5 works well for most cases.

#### Rating Periods

Glicko-2 works best when you batch games into **rating periods** instead of updating after every single game. Think of it like updating ratings once a week instead of after each match.

**How many games per period?** Aim for 10-15 games per player, minimum 5.

**How long should a period be?**

- Active games: 1 day to 1 week
- Normal activity: 1-2 weeks  
- Slow games: 2 weeks to 1 month

Here's the basic flow:

```dart
// Collect all matches during the rating period
final playerMatches = <String, List<MatchResult>>{};

// ... games happen ...

// At the end of the period, update everyone at once
for (final playerId in playerMatches.keys) {
  final currentRating = getCurrentRating(playerId);
  final matches = playerMatches[playerId]!;
  
  final newRating = glicko.calculateNewRating(currentRating, matches);
  saveRating(playerId, newRating);
}
```

### Elo

#### Quick Start

```dart
import 'package:matchmaker/matchmaker.dart';

void main() {
  const elo = Elo();

  // Players start with a rating (usually 1500)
  const ricardo = EloRating(rating: 1500);
  const lucas = EloRating(rating: 1400);

  // Ricardo beats Lucas
  final results = [MatchResult.win(lucas)];
  final newRating = elo.calculateNewRating(ricardo, results);

  print('Ricardo new rating: ${newRating.rating.toStringAsFixed(0)}');
  // Output: Ricardo new rating: 1521
}
```

#### Predict match outcomes

```dart
const elo = Elo();
const stronger = EloRating(rating: 1700);
const weaker = EloRating(rating: 1500);

final winChance = elo.predictOutcome(stronger, weaker);
print('Win probability: ${(winChance * 100).toStringAsFixed(1)}%');
// Output: Win probability: 76.0%
```

#### Series of games

```dart
const elo = Elo();
var player = const EloRating(rating: 1500);
const opponent = EloRating(rating: 1600);

// Player loses, then wins, then draws
player = elo.calculateNewRating(player, [MatchResult.loss(opponent)]);
player = elo.calculateNewRating(player, [MatchResult.win(opponent)]);
player = elo.calculateNewRating(player, [MatchResult.draw(opponent)]);

print('Final rating: ${player.rating.toStringAsFixed(0)}');
```

#### Multiple games at once

```dart
const elo = Elo();
const player = EloRating(rating: 1500);
const opponent = EloRating(rating: 1600);

// Process multiple games in one batch
final results = [
  MatchResult.win(opponent),
  MatchResult.loss(opponent),
  MatchResult.draw(opponent),
];

final newRating = elo.calculateNewRating(player, results);
```

#### Configuration

```dart
const elo = Elo(
  kFactor: 16,        // How fast ratings change (10-32)
  defaultRating: 1500, // Starting rating for new players
);
```

**kFactor**: Controls how much ratings change per game

- **32**: Fast changes, good for newer players (USCF standard)
- **24**: Medium speed
- **16**: Slower changes, good for established players  
- **10**: Very stable, for high-level play (FIDE standard)

Lower K-factors make ratings more stable but slower to adjust. Higher values let ratings adapt quickly but can be more volatile.

## License

MIT
