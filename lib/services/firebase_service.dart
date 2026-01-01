import 'package:cloud_firestore/cloud_firestore.dart';

/// Service class to handle all Firebase Firestore operations for Flordle (Wordle clone)
///
/// Database Collections:
/// - games: Individual game sessions
/// - statistics: Player stats and win streaks
/// - daily_words: The word for each day
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection names
  static const String _gamesCollection = 'games';
  static const String _statisticsCollection = 'statistics';
  static const String _dailyWordsCollection = 'daily_words';

  // ============================================
  // DAILY WORDS
  // ============================================

  /// Set the word for a specific date
  Future<void> setDailyWord({
    required String date,
    required String word,
  }) async {
    await _firestore.collection(_dailyWordsCollection).doc(date).set({
      'word': word.toUpperCase(),
      'date': date,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get the word for a specific date
  Future<String?> getDailyWord(String date) async {
    final doc = await _firestore.collection(_dailyWordsCollection).doc(date).get();
    if (doc.exists) {
      return doc.data()?['word'] as String?;
    }
    return null;
  }

  /// Get today's word
  Future<String?> getTodayWord() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return await getDailyWord(today);
  }

  // ============================================
  // GAMES
  // ============================================

  /// Save a completed game
  Future<void> saveGame({
    required String playerName,
    required String word,
    required List<String> guesses,
    required bool won,
    required int attempts,
  }) async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    await _firestore.collection(_gamesCollection).add({
      'playerName': playerName,
      'word': word.toUpperCase(),
      'guesses': guesses.map((g) => g.toUpperCase()).toList(),
      'won': won,
      'attempts': attempts,
      'date': today,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Also update player statistics
    await updatePlayerStats(
      playerName: playerName,
      won: won,
      attempts: won ? attempts : null,
    );
  }

  /// Get all games for a player
  Future<List<Map<String, dynamic>>> getPlayerGames(String playerName) async {
    final snapshot = await _firestore
        .collection(_gamesCollection)
        .where('playerName', isEqualTo: playerName)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Check if player already played today
  Future<bool> hasPlayedToday(String playerName) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final snapshot = await _firestore
        .collection(_gamesCollection)
        .where('playerName', isEqualTo: playerName)
        .where('date', isEqualTo: today)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // ============================================
  // STATISTICS
  // ============================================

  /// Update or create player statistics after a game
  Future<void> updatePlayerStats({
    required String playerName,
    required bool won,
    int? attempts,
  }) async {
    final docRef = _firestore.collection(_statisticsCollection).doc(playerName);
    final doc = await docRef.get();

    if (doc.exists) {
      // Update existing stats
      final data = doc.data()!;
      final gamesPlayed = (data['gamesPlayed'] as int? ?? 0) + 1;
      final gamesWon = (data['gamesWon'] as int? ?? 0) + (won ? 1 : 0);
      final currentStreak = won ? (data['currentStreak'] as int? ?? 0) + 1 : 0;
      final maxStreak = data['maxStreak'] as int? ?? 0;

      // Update guess distribution
      final distribution = Map<String, int>.from(
        (data['guessDistribution'] as Map? ?? {}).map(
          (k, v) => MapEntry(k.toString(), v as int),
        ),
      );
      if (won && attempts != null) {
        distribution[attempts.toString()] =
            (distribution[attempts.toString()] ?? 0) + 1;
      }

      await docRef.update({
        'gamesPlayed': gamesPlayed,
        'gamesWon': gamesWon,
        'currentStreak': currentStreak,
        'maxStreak': currentStreak > maxStreak ? currentStreak : maxStreak,
        'winRate': (gamesWon / gamesPlayed * 100).round(),
        'guessDistribution': distribution,
        'lastPlayed': FieldValue.serverTimestamp(),
      });
    } else {
      // Create new player stats
      await docRef.set({
        'playerName': playerName,
        'gamesPlayed': 1,
        'gamesWon': won ? 1 : 0,
        'currentStreak': won ? 1 : 0,
        'maxStreak': won ? 1 : 0,
        'winRate': won ? 100 : 0,
        'guessDistribution': won && attempts != null
            ? {attempts.toString(): 1}
            : {},
        'lastPlayed': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Get player statistics
  Future<Map<String, dynamic>?> getPlayerStats(String playerName) async {
    final doc = await _firestore
        .collection(_statisticsCollection)
        .doc(playerName)
        .get();

    return doc.exists ? doc.data() : null;
  }

  /// Get leaderboard (top players by win rate)
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    final snapshot = await _firestore
        .collection(_statisticsCollection)
        .orderBy('winRate', descending: true)
        .orderBy('gamesPlayed', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // ============================================
  // REAL-TIME STREAMS
  // ============================================

  /// Stream of player statistics (for real-time UI updates)
  Stream<Map<String, dynamic>?> playerStatsStream(String playerName) {
    return _firestore
        .collection(_statisticsCollection)
        .doc(playerName)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  /// Stream of leaderboard
  Stream<List<Map<String, dynamic>>> leaderboardStream({int limit = 10}) {
    return _firestore
        .collection(_statisticsCollection)
        .orderBy('winRate', descending: true)
        .orderBy('gamesPlayed', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // ============================================
  // UTILITIES
  // ============================================

  /// Delete all data for a player (for testing)
  Future<void> deletePlayerData(String playerName) async {
    // Delete stats
    await _firestore.collection(_statisticsCollection).doc(playerName).delete();

    // Delete games
    final games = await _firestore
        .collection(_gamesCollection)
        .where('playerName', isEqualTo: playerName)
        .get();

    for (final doc in games.docs) {
      await doc.reference.delete();
    }
  }

  /// Seed daily words for testing (adds words for the next 7 days)
  Future<void> seedDailyWords() async {
    const words = ['CRANE', 'SLATE', 'AUDIO', 'RAISE', 'STARE', 'HOUSE', 'PLANT'];
    final now = DateTime.now();

    for (int i = 0; i < words.length; i++) {
      final date = now.add(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];
      await setDailyWord(date: dateStr, word: words[i]);
    }
  }
}
