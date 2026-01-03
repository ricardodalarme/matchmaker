import 'package:matchmaker/src/rating.dart';

/// Represents a TrueSkill rating for a player.
///
/// TrueSkill represents skill using a Gaussian distribution with two parameters:
/// - [mu] (μ): The mean skill level
/// - [sigma] (σ): The uncertainty/standard deviation
///
/// A player's "true skill" is believed to be μ ± 2σ with 95% confidence.
class TrueSkillRating implements Rating {
  /// Creates a TrueSkill rating.
  ///
  /// [mu] is the mean skill (typically starts at 25.0).
  /// [sigma] is the skill uncertainty (typically starts at 8.333).
  const TrueSkillRating({
    required this.mu,
    required this.sigma,
  });

  /// The mean skill level (μ).
  ///
  /// This represents the average skill of the player. Higher values indicate
  /// stronger players. The default starting value is 25.0.
  final double mu;

  /// The skill uncertainty (σ).
  ///
  /// This represents how confident the system is about the player's skill.
  /// Lower values indicate more confidence. The default starting value is 8.333.
  /// After many games, this typically decreases to around 2-3.
  final double sigma;

  @override
  double get rating => mu;

  /// Returns the conservative skill estimate (μ - 3σ).
  ///
  /// This is the value displayed in leaderboards. It represents a conservative
  /// estimate where there's a 99% chance the player's true skill is higher.
  /// New players start at 0 (25 - 3*8.333 = 0).
  double get conservativeRating => mu - 3 * sigma;

  /// Returns the exposure value (μ - k*σ).
  ///
  /// Similar to conservative rating but allows customizing the multiplier.
  /// Use this for sorting leaderboards with different confidence levels.
  double exposure([double k = 3]) => mu - k * sigma;

  @override
  String toString() => 'TrueSkillRating(mu: ${mu.toStringAsFixed(2)}, '
      'sigma: ${sigma.toStringAsFixed(2)}, '
      'conservative: ${conservativeRating.toStringAsFixed(2)})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrueSkillRating &&
          runtimeType == other.runtimeType &&
          mu == other.mu &&
          sigma == other.sigma;

  @override
  int get hashCode => Object.hash(mu, sigma);
}
