/// Model class representing player statistics
class PlayerStats {
  final String playerName;
  final int gamesPlayed;
  final int gamesWon;
  final int currentStreak;
  final int maxStreak;
  final int winRate;
  final Map<String, int> guessDistribution;
  final DateTime? lastPlayed;

  PlayerStats({
    required this.playerName,
    required this.gamesPlayed,
    required this.gamesWon,
    required this.currentStreak,
    required this.maxStreak,
    required this.winRate,
    required this.guessDistribution,
    this.lastPlayed,
  });

  /// Create PlayerStats from Firestore document
  factory PlayerStats.fromMap(Map<String, dynamic> map) {
    // Convert guessDistribution from dynamic to Map<String, int>
    Map<String, int> distribution = {};
    if (map['guessDistribution'] != null) {
      (map['guessDistribution'] as Map).forEach((key, value) {
        distribution[key.toString()] = value as int;
      });
    }

    return PlayerStats(
      playerName: map['playerName'] as String,
      gamesPlayed: map['gamesPlayed'] as int? ?? 0,
      gamesWon: map['gamesWon'] as int? ?? 0,
      currentStreak: map['currentStreak'] as int? ?? 0,
      maxStreak: map['maxStreak'] as int? ?? 0,
      winRate: map['winRate'] as int? ?? 0,
      guessDistribution: distribution,
      lastPlayed: map['lastPlayed'] != null
          ? DateTime.parse(map['lastPlayed'].toString())
          : null,
    );
  }

  /// Convert PlayerStats to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'playerName': playerName,
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
      'currentStreak': currentStreak,
      'maxStreak': maxStreak,
      'winRate': winRate,
      'guessDistribution': guessDistribution,
    };
  }

  /// Get games lost
  int get gamesLost => gamesPlayed - gamesWon;

  /// Get win percentage as double (0-100)
  double get winPercentage => gamesPlayed > 0
      ? (gamesWon / gamesPlayed * 100)
      : 0.0;

  @override
  String toString() {
    return 'PlayerStats(player: $playerName, played: $gamesPlayed, won: $gamesWon, winRate: $winRate%, streak: $currentStreak)';
  }
}

