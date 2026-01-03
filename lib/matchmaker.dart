/// A pure Dart package for skill rating and matchmaking systems.
///
/// Matchmaker provides battle-tested rating algorithms for competitive games
/// and multiplayer applications.
///
/// Supported Rating Systems
/// * Glicko-2
/// * Elo
/// * TrueSkill
library;

export 'src/elo/elo.dart';
export 'src/elo/elo_rating.dart';
export 'src/glicko2/glicko2.dart';
export 'src/glicko2/glicko2_rating.dart';
export 'src/match_result.dart';
export 'src/rating.dart';
export 'src/trueskill/trueskill.dart';
export 'src/trueskill/trueskill_rating.dart';
