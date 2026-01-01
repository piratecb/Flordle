# Firebase Database Structure for Flordle (Wordle Clone)

## Overview
This Firestore database structure replicates the New York Times Wordle game functionality.

**Firebase Console:** https://console.firebase.google.com/u/0/project/flordle-tpsi2526/firestore

## Collections

### 1. `daily_words` Collection
Stores the daily word for each date. **One word per day**, just like NYT Wordle.

**Document ID:** `YYYY-MM-DD` (e.g., "2026-01-01")

```json
{
  "word": "CRANE",           // 5-letter word (uppercase)
  "date": "2026-01-01",      // Same as document ID
  "createdAt": Timestamp     // When it was set
}
```

---

### 2. `games` Collection
Stores each completed game session.

**Document ID:** Auto-generated

```json
{
  "playerName": "john_doe",              // Player identifier
  "word": "CRANE",                       // The target word
  "guesses": ["STARE", "CRANE"],         // All guesses made
  "won": true,                           // Win or loss
  "attempts": 2,                         // Number of attempts (1-6)
  "date": "2026-01-01",                  // Date played
  "timestamp": Timestamp                 // Server timestamp
}
```

---

### 3. `statistics` Collection
Player statistics like NYT Wordle stats screen.

**Document ID:** `{playerName}`

```json
{
  "playerName": "john_doe",
  "gamesPlayed": 50,                     // Total games
  "gamesWon": 42,                        // Total wins
  "currentStreak": 5,                    // Current win streak
  "maxStreak": 15,                       // Best win streak
  "winRate": 84,                         // Win percentage (0-100)
  "guessDistribution": {                 // Wins by attempt count
    "1": 2,
    "2": 8,
    "3": 15,
    "4": 12,
    "5": 4,
    "6": 1
  },
  "lastPlayed": Timestamp                // Last game time
}
```

---

## Firestore Rules (Development Mode)

Currently set to allow all access for development:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /games/{gameId} {
      allow read, write: if true;
    }
    match /statistics/{playerName} {
      allow read, write: if true;
    }
    match /daily_words/{date} {
      allow read, write: if true;
    }
  }
}
```

---

## Usage Examples

### Set today's word:
```dart
final firebase = FirebaseService();
await firebase.setDailyWord(date: '2026-01-01', word: 'CRANE');
```

### Get today's word:
```dart
String? word = await firebase.getTodayWord();
```

### Save a completed game:
```dart
await firebase.saveGame(
  playerName: 'john_doe',
  word: 'CRANE',
  guesses: ['STARE', 'CRANE'],
  won: true,
  attempts: 2,
);
```

### Get player stats:
```dart
Map<String, dynamic>? stats = await firebase.getPlayerStats('john_doe');
```

### Check if player already played today:
```dart
bool played = await firebase.hasPlayedToday('john_doe');
```

### Seed words for the next 7 days:
```dart
await firebase.seedDailyWords();
```

---

## How It Works (Like NYT Wordle)

1. **Daily Word**: Each day has exactly one word stored in `daily_words/{date}`
2. **One Game Per Day**: Use `hasPlayedToday()` to check if player already played
3. **Statistics**: Automatically updated when `saveGame()` is called
4. **Streaks**: Winning streak resets to 0 on a loss
5. **Guess Distribution**: Shows how many wins with 1, 2, 3, 4, 5, or 6 guesses

