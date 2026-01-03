# Matchmaker

[![pub package](https://img.shields.io/pub/v/matchmaker.svg)](https://pub.dev/packages/matchmaker)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Rating algorithms for competitive games and multiplayer applications. Implements Elo, Glicko-2, and TrueSkill.

## Installation

```bash
dart pub add matchmaker
```

## Supported Algorithms

| Algorithm | Use Case | Complexity | Tracks Uncertainty | Team Support |
|-----------|----------|------------|-------------------|--------------|
| **Elo** | 1v1 games | Low | No | No |
| **Glicko-2** | 1v1 competitive | Medium | Yes (RD + volatility) | No |
| **TrueSkill** | Team/multiplayer | High | Yes (sigma) | Yes |

## Quick Start

```dart
import 'package:matchmaker/matchmaker.dart';

// Elo
const elo = Elo();
final newRating = elo.calculateNewRating(
  const EloRating(rating: 1500),
  [MatchResult.win(const EloRating(rating: 1400))],
);

// Glicko-2
const glicko = Glicko2();
final newGlicko = glicko.calculateNewRating(
  const Glicko2Rating(rating: 1500, rd: 200, volatility: 0.06),
  [MatchResult.win(const Glicko2Rating(rating: 1400, rd: 30, volatility: 0.06))],
);

// TrueSkill (1v1)
const trueskill = TrueSkill();
final results = trueskill.rate(
  [[trueskill.createRating()], [trueskill.createRating()]],
  ranks: [0, 1],
);
```

## Configuration

### Elo

```dart
const elo = Elo(
  kFactor: 32,         // Rating change speed (10-32)
  defaultRating: 1500, // Starting rating
);
```

**K-Factor Guidelines:**
- `32`: New/active players (USCF)
- `24`: Intermediate
- `16`: Established players
- `10`: Masters (FIDE)

### Glicko-2

```dart
const glicko = Glicko2(
  volatilityConstraint: 0.5,      // Volatility change rate (0.3-1.2)
  convergenceTolerance: 0.000001, // Calculation precision
);

// Default initial rating
const player = Glicko2Rating(
  rating: 1500,
  rd: 350,          // Rating deviation (uncertainty)
  volatility: 0.06,
);
```

**Volatility Constraint:**
- `0.3-0.6`: Stable, consistent performance
- `0.8-1.2`: Volatile, unpredictable performance

**Rating Periods:** Batch 10-15 games per player for optimal accuracy.

### TrueSkill

```dart
const trueskill = TrueSkill(
  mu: 25.0,              // Mean skill
  sigma: 8.333,          // Initial uncertainty (mu/3)
  beta: 4.167,           // Performance variance (sigma/2)
  tau: 0.0833,           // Skill dynamics (sigma/100)
  drawProbability: 0.10, // Draw rate in your game
);
```

**Parameters:**
- **beta**: Smaller values = more deterministic outcomes
- **tau**: Prevents over-confidence in stable players
- **drawProbability**: Set based on your game's actual draw rate

## Algorithm Selection Guide

| Requirement | Recommended System |
|-------------|-------------------|
| Simple 1v1 ranking | Elo |
| Track rating confidence | Glicko-2 |
| Variable player activity | Glicko-2 |
| Team matches (2v2, 3v3, etc.) | TrueSkill |
| Free-for-all (3+ players) | TrueSkill |
| Match quality prediction | TrueSkill |
| Transparent to players | Elo |

## Implementation Tips

- **Initial Uncertainty:** Start new players with high RD (Glicko-2) or sigma (TrueSkill) for faster convergence.
- **Batch Updates:** Process match results in rating periods (Glicko-2) or after game sessions for consistency.
- **Leaderboards:** Use conservative rating (μ - 3σ) for TrueSkill to avoid displaying inflated ratings.
- **1v1 in Team Systems:** Elo and Glicko-2 are mathematically optimized for 1v1. Use TrueSkill only if you need team/multiplayer support.

## Examples

Detailed implementations available in the repository:

- [**Elo Example**](example/elo_example.dart) - Basic usage, series of games, K-factor comparison
- [**Glicko-2 Example**](example/glicko2_example.dart) - Rating periods, tournaments, confidence intervals
- [**TrueSkill Example**](example/trueskill_example.dart) - Teams, free-for-all, match quality, partial play

## License

MIT
