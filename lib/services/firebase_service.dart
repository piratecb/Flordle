import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projeto_prog_mobile_wordle/models/game_model.dart';
import 'package:projeto_prog_mobile_wordle/models/player_stats.dart';

/// Service class to handle all Firebase Firestore operations
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String gamesCollection = 'games';
  static const String statisticsCollection = 'statistics';

  // ==================== GAMES ====================

  /// Save a completed game to Firebase
  Future<void> saveGame(GameModel game) async {
    try {
      await _firestore.collection(gamesCollection).add(game.toMap());
      print('✅ Jogo salvo com sucesso');
    } catch (e) {
      print('❌ Erro ao salvar jogo: $e');
      rethrow;
    }
  }

  /// Get all games for a specific player
  Future<List<GameModel>> getPlayerGames(String playerName) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(gamesCollection)
          .where('playerName', isEqualTo: playerName)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return GameModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ Erro ao buscar jogos do jogador: $e');
      return [];
    }
  }

  /// Get all games for a specific date
  Future<List<GameModel>> getGamesByDate(String date) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(gamesCollection)
          .where('date', isEqualTo: date)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return GameModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ Erro ao buscar jogos por data: $e');
      return [];
    }
  }

  /// Get recent games (limit)
  Future<List<GameModel>> getRecentGames({int limit = 20}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(gamesCollection)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return GameModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ Erro ao buscar jogos recentes: $e');
      return [];
    }
  }

  /// Stream of games (real-time updates)
  Stream<List<GameModel>> streamGames({int limit = 50}) {
    return _firestore
        .collection(gamesCollection)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return GameModel.fromMap(data);
      }).toList();
    });
  }

  // ==================== STATISTICS ====================

  /// Get player statistics
  Future<PlayerStats?> getPlayerStats(String playerName) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(statisticsCollection)
          .doc(playerName)
          .get();

      if (doc.exists) {
        return PlayerStats.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('❌ Erro ao buscar estatísticas: $e');
      return null;
    }
  }

  /// Update or create player statistics
  Future<void> updatePlayerStats(String playerName, GameModel game) async {
    try {
      DocumentReference docRef = _firestore
          .collection(statisticsCollection)
          .doc(playerName);

      DocumentSnapshot doc = await docRef.get();

      if (doc.exists) {
        // Update existing stats
        PlayerStats currentStats = PlayerStats.fromMap(doc.data() as Map<String, dynamic>);

        int newGamesPlayed = currentStats.gamesPlayed + 1;
        int newGamesWon = currentStats.gamesWon + (game.won ? 1 : 0);
        int newWinRate = ((newGamesWon / newGamesPlayed) * 100).round();

        // Update streak
        int newCurrentStreak = game.won ? currentStats.currentStreak + 1 : 0;
        int newMaxStreak = newCurrentStreak > currentStats.maxStreak
            ? newCurrentStreak
            : currentStats.maxStreak;

        // Update guess distribution
        Map<String, int> newGuessDistribution = Map.from(currentStats.guessDistribution);
        if (game.won) {
          String attemptsKey = game.attempts.toString();
          newGuessDistribution[attemptsKey] = (newGuessDistribution[attemptsKey] ?? 0) + 1;
        }

        await docRef.update({
          'gamesPlayed': newGamesPlayed,
          'gamesWon': newGamesWon,
          'winRate': newWinRate,
          'currentStreak': newCurrentStreak,
          'maxStreak': newMaxStreak,
          'guessDistribution': newGuessDistribution,
          'lastPlayed': DateTime.now().toIso8601String(),
        });

        print('✅ Estatísticas atualizadas');
      } else {
        // Create new stats
        Map<String, int> guessDistribution = {};
        if (game.won) {
          guessDistribution[game.attempts.toString()] = 1;
        }

        PlayerStats newStats = PlayerStats(
          playerName: playerName,
          gamesPlayed: 1,
          gamesWon: game.won ? 1 : 0,
          currentStreak: game.won ? 1 : 0,
          maxStreak: game.won ? 1 : 0,
          winRate: game.won ? 100 : 0,
          guessDistribution: guessDistribution,
          lastPlayed: DateTime.now(),
        );

        await docRef.set(newStats.toMap());
        print('✅ Novas estatísticas criadas');
      }
    } catch (e) {
      print('❌ Erro ao atualizar estatísticas: $e');
      rethrow;
    }
  }

  /// Get all player statistics
  Future<List<PlayerStats>> getAllPlayerStats() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(statisticsCollection)
          .orderBy('gamesPlayed', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return PlayerStats.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('❌ Erro ao buscar todas as estatísticas: $e');
      return [];
    }
  }

  /// Stream of player statistics (real-time updates)
  Stream<PlayerStats?> streamPlayerStats(String playerName) {
    return _firestore
        .collection(statisticsCollection)
        .doc(playerName)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return PlayerStats.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // ==================== UTILITY ====================

  /// Delete all data (use with caution - for testing only)
  Future<void> clearAllData() async {
    try {
      // Delete all games
      var gamesSnapshot = await _firestore.collection(gamesCollection).get();
      for (var doc in gamesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all statistics
      var statsSnapshot = await _firestore.collection(statisticsCollection).get();
      for (var doc in statsSnapshot.docs) {
        await doc.reference.delete();
      }

      print('✅ Todos os dados foram apagados');
    } catch (e) {
      print('❌ Erro ao limpar dados: $e');
      rethrow;
    }
  }

  /// Check if player has already played today
  Future<bool> hasPlayedToday(String playerName, String date) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(gamesCollection)
          .where('playerName', isEqualTo: playerName)
          .where('date', isEqualTo: date)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Erro ao verificar se jogou hoje: $e');
      return false;
    }
  }
}

