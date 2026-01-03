/// Model class representing a completed Wordle game
class GameModel {
  final String? id;
  final String playerName;
  final String word;
  final List<String> guesses;
  final bool won;
  final int attempts;
  final DateTime? timestamp;
  final String date;
  final int? durationSeconds; // Duração do jogo em segundos

  GameModel({
    this.id,
    required this.playerName,
    required this.word,
    required this.guesses,
    required this.won,
    required this.attempts,
    this.timestamp,
    required this.date,
    this.durationSeconds,
  });

  /// Create GameModel from Firestore document
  factory GameModel.fromMap(Map<String, dynamic> map) {
    return GameModel(
      id: map['id'] as String?,
      playerName: map['playerName'] as String,
      word: map['word'] as String,
      guesses: List<String>.from(map['guesses'] as List),
      won: map['won'] as bool,
      attempts: map['attempts'] as int,
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'].toString())
          : null,
      date: map['date'] as String,
      durationSeconds: map['durationSeconds'] as int?,
    );
  }

  /// Convert GameModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'playerName': playerName,
      'word': word,
      'guesses': guesses,
      'won': won,
      'attempts': attempts,
      'date': date,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
    };
  }

  @override
  String toString() {
    return 'GameModel(playerName: $playerName, word: $word, won: $won, attempts: $attempts)';
  }
}

