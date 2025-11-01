[![pub package](https://img.shields.io/pub/v/matchmaker.svg)](https://pub.dev/packages/matchmaker)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# Matchmaker

A pure Dart package for video game skill rating systems. Matchmaker provides robust implementations of rating algorithms designed to accurately assess player skill in competitive gaming environments.

## What is Glicko-2?

The Glicko-2 rating system, developed by Dr. Mark E. Glickman at Boston University, is an improvement over the classic Elo rating system. Unlike Elo, which only tracks a single rating value, Glicko-2 maintains three values for each player:

- **Rating**: The player's skill level (higher = better, typically centered around 1500)
- **Rating Deviation (RD)**: Uncertainty in the rating (lower = more certain). New players start with high RD, which decreases as they play more games.
- **Volatility**: Expected fluctuation in the player's rating. High volatility indicates erratic or inconsistent performance.

### Key advantages over Elo:

1. **Accounts for uncertainty**: A player who hasn't played in a while will have higher RD, allowing their rating to adjust more quickly when they return
2. **Consistent performance tracking**: Volatility measures how reliably a player performs at their rating level
3. **Better handling of inactive players**: RD increases over time when not playing, reflecting increased uncertainty
4. **Rating periods**: Designed to process multiple games in batches for more accurate adjustments

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  matchmaker: ^0.1.0
```

## Usage

### Basic Example

```dart
import 'package:matchmaker/matchmaker.dart';

void main() {
  // Create a Glicko-2 rating system
  const glicko = Glicko2();

  // Create player ratings (new players get default values)
  const alice = Glicko2Rating(
    rating: 1500,     // Starting rating
    rd: 200,          // Rating deviation
    volatility: 0.06, // Volatility
  );

  const bob = Glicko2Rating(
    rating: 1400,
    rd: 30,
    volatility: 0.06,
  );

  // Record match results (from Alice's perspective)
  final results = [
    MatchResult.win(bob),  // Alice beat Bob
  ];

  // Calculate Alice's new rating after the match
  final aliceNewRating = glicko.calculateNewRating(alice, results);

  print('Alice new rating: ${aliceNewRating.rating.toStringAsFixed(0)}');
  print('Alice new RD: ${aliceNewRating.rd.toStringAsFixed(2)}');
  print('Alice new volatility: ${aliceNewRating.volatility.toStringAsFixed(5)}');
}
```

### Tournament Example

```dart
void tournamentExample() {
  const glicko = Glicko2();

  // Four players start a tournament
  const alice = Glicko2Rating(rating: 1500, rd: 200, volatility: 0.06);
  const bob = Glicko2Rating(rating: 1400, rd: 150, volatility: 0.06);
  const charlie = Glicko2Rating(rating: 1600, rd: 180, volatility: 0.06);
  const diana = Glicko2Rating(rating: 1550, rd: 170, volatility: 0.06);

  // Alice's matches during the tournament
  final aliceResults = [
    MatchResult.win(bob),        // Beat Bob
    MatchResult.loss(charlie),   // Lost to Charlie
    MatchResult.draw(diana),     // Drew with Diana
  ];

  // Calculate new rating after the tournament
  final aliceNew = glicko.calculateNewRating(alice, aliceResults);

  print('Alice rating change: ${aliceNew.rating - alice.rating}');
}
```

### Predicting Match Outcomes

```dart
void predictionExample() {
  const glicko = Glicko2();

  const strongPlayer = Glicko2Rating(rating: 1800, rd: 50, volatility: 0.06);
  const weakPlayer = Glicko2Rating(rating: 1200, rd: 200, volatility: 0.06);

  // Predict win probability
  final winProbability = glicko.predictOutcome(strongPlayer, weakPlayer);

  print('Strong player win probability: ${(winProbability * 100).toStringAsFixed(1)}%');
  // Output: Strong player win probability: 99.7%
}
```

### Confidence Intervals

```dart
void confidenceIntervalExample() {
  const player = Glicko2Rating(rating: 1650, rd: 80, volatility: 0.06);

  // Get 95% confidence interval
  final interval = player.getConfidenceInterval();

  print('95% confident that true skill is between '
        '${interval.lower.toStringAsFixed(0)} and '
        '${interval.upper.toStringAsFixed(0)}');
  // Output: 95% confident that true skill is between 1493 and 1807
}
```

### Handling Inactive Players

When a player doesn't compete during a rating period, their rating stays the same but their RD increases (uncertainty grows):

```dart
void inactivityExample() {
  const glicko = Glicko2();
  var player = const Glicko2Rating(rating: 1600, rd: 50, volatility: 0.06);

  // Player doesn't play for a rating period
  player = glicko.applyRatingPeriodWithoutGames(player);

  // Rating unchanged, but RD increased
  print('Rating: ${player.rating}');  // Still 1600
  print('RD: ${player.rd}');           // Now higher than 50
}
```

## Configuration

You can customize the Glicko-2 system parameters:

```dart
const glicko = Glicko2(
  tau: 0.5,                  // Volatility constraint (0.3-1.2, default: 0.5)
  defaultRating: 1500,       // Starting rating for new players
  defaultRd: 350,            // Starting RD for new players
  defaultVolatility: 0.06,   // Starting volatility for new players
  epsilon: 0.000001,         // Convergence tolerance
);
```

### Parameter Guidelines

- **tau**: Constrains how much volatility can change. Use 0.3-0.6 for stable games, 0.8-1.2 for games with more variance. Test to find optimal value.
- **defaultRating**: Standard is 1500, but can be adjusted to your preference
- **defaultRd**: 350 is standard for completely new players. Lower values (200-250) can be used if you have some prior information.
- **defaultVolatility**: 0.06 is standard. Lower values (0.04-0.05) for consistent games, higher (0.07-0.09) for variable games.

## Rating Periods

Glicko-2 is designed to process games in **rating periods** - batches of games that are treated as occurring simultaneously. This is more accurate than updating ratings after each individual game.

### Recommendations:

- **Optimal**: 10-15 games per player per rating period
- **Minimum**: 5 games per player
- **Period length**: Depends on your game's activity level
  - High activity games: 1 day to 1 week
  - Medium activity: 1-2 weeks
  - Low activity: 2 weeks to 1 month

Example workflow:

```dart
void ratingPeriodWorkflow() {
  const glicko = Glicko2();
  
  // Store all matches that occur during the rating period
  final playerMatches = <String, List<MatchResult>>{};
  
  // ... collect matches during the rating period ...
  
  // At the end of the rating period, update all players
  final updatedRatings = <String, Glicko2Rating>{};
  
  for (final entry in playerMatches.entries) {
    final playerId = entry.key;
    final currentRating = getCurrentRating(playerId);
    final matches = entry.value;
    
    updatedRatings[playerId] = glicko.calculateNewRating(
      currentRating,
      matches,
    );
  }
  
  // Save updated ratings for the next period
  saveRatings(updatedRatings);
}
```

## References

- [Glicko-2 Rating System](http://www.glicko.net/glicko/glicko2.pdf) - Official paper by Dr. Mark E. Glickman
- [Glicko Website](http://www.glicko.net/) - Dr. Glickman's website with additional resources
