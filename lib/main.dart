import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:projeto_prog_mobile_wordle/data/word_list.dart';
import 'package:projeto_prog_mobile_wordle/screens/login_screen.dart';
import 'package:projeto_prog_mobile_wordle/screens/stats_screen.dart';
import 'package:projeto_prog_mobile_wordle/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const wordle());

}

class wordle extends StatefulWidget {
  const wordle({super.key});

  @override
  State<wordle> createState() => _wordleState();
}

class _wordleState extends State<wordle> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/login': (context) => LoginScreen(),
        '/stats': (context) => StatsScreen(),
      },
    );
  }
}

// Tela inicial do Wordle
class HomeScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'F',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green[400],
              ),
            ),
            Text(
              'L',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.amber[600],
              ),
            ),
            const Text(
              'ORDLE',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[850],
        leading: IconButton(
          icon: const Icon(Icons.bar_chart_rounded, color: Colors.white),
          tooltip: 'Estatísticas',
          onPressed: () {
            Navigator.pushNamed(context, '/stats');
          },
        ),
        actions: [
          StreamBuilder(
            stream: _authService.authStateChanges,
            builder: (context, snapshot) {
              final user = _authService.currentUser;
              final isLoggedIn = user != null && !user.isAnonymous;

              return IconButton(
                icon: Icon(
                  isLoggedIn ? Icons.account_circle : Icons.account_circle_outlined,
                  color: isLoggedIn ? Colors.green[400] : Colors.white,
                  size: 28,
                ),
                tooltip: isLoggedIn ? 'Perfil' : 'Entrar',
                onPressed: () {
                  if (isLoggedIn) {
                    Navigator.pushNamed(context, '/stats');
                  } else {
                    Navigator.pushNamed(context, '/login');
                  }
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: WordleBody(),
      ),
    );
  }
}

// Corpo do jogo Wordle
class WordleBody extends StatefulWidget {
  @override
  State<WordleBody> createState() => _WordleBodyState();
}

class _WordleBodyState extends State<WordleBody> {
  // Services
  final AuthService _authService = AuthService();

  // Game state
  static const int maxAttempts = 6;
  static const int wordLength = 5;

  // Stats tracking
  bool _statsSaved = false;

  // Grid of letters - 6 rows x 5 columns
  List<List<String>> grid = List.generate(
    maxAttempts,
    (_) => List.generate(wordLength, (_) => ''),
  );

  // Grid of colors - 6 rows x 5 columns
  // 0 = default (gray/dark), 1 = wrong (dark gray), 2 = wrong position (yellow), 3 = correct (green)
  List<List<int>> colorGrid = List.generate(
    maxAttempts,
    (_) => List.generate(wordLength, (_) => 0),
  );

  // Current position
  int currentRow = 0;
  int currentCol = 0;

  // Today's word
  late String targetWord;

  // Game over state
  bool gameOver = false;
  bool won = false;

  // Keyboard letter colors
  // 0 = default, 1 = wrong (dark gray), 2 = wrong position (yellow), 3 = correct (green)
  Map<String, int> keyboardColors = {};

  @override
  void initState() {
    super.initState();
    _selectDailyWord();
  }

  // Select the daily word based on date
  void _selectDailyWord() {
    final now = DateTime.now();
    // Use day of year as index to get a consistent daily word
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final wordIndex = dayOfYear % WordList.words.length;
    targetWord = WordList.words[wordIndex];
    print('🎯 Palavra do dia: $targetWord'); // Debug - remove in production
  }

  // Add a letter to the current position
  void _addLetter(String letter) {
    if (gameOver) return;
    if (currentRow < maxAttempts && currentCol < wordLength) {
      setState(() {
        grid[currentRow][currentCol] = letter;
        currentCol++;
      });
    }
  }

  // Remove the last letter (backspace)
  void _removeLetter() {
    if (gameOver) return;
    if (currentCol > 0) {
      setState(() {
        currentCol--;
        grid[currentRow][currentCol] = '';
      });
    }
  }

  // Submit the current guess (ENTER)
  void _submitGuess() {
    if (gameOver) return;
    if (currentCol == wordLength) {
      // Get the current guess
      String guess = grid[currentRow].join();

      // Check if word is in the word list
      if (!WordList.isValidWord(guess)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Palavra não existe na lista!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate and color the guess
      _validateGuess(guess);

      // Check if won
      if (guess == targetWord) {
        setState(() {
          gameOver = true;
          won = true;
        });
        _showGameEndDialog(true);
        return;
      }

      // Move to next row
      setState(() {
        currentRow++;
        currentCol = 0;
      });

      // Check if game over (no more attempts)
      if (currentRow >= maxAttempts) {
        setState(() {
          gameOver = true;
          won = false;
        });
        _showGameEndDialog(false);
      }
    }
  }

  // Validate the guess and set colors
  void _validateGuess(String guess) {
    // Create a map to track remaining letters in target word
    Map<String, int> targetLetterCount = {};
    for (int i = 0; i < targetWord.length; i++) {
      String letter = targetWord[i];
      targetLetterCount[letter] = (targetLetterCount[letter] ?? 0) + 1;
    }

    // First pass: Mark correct positions (green)
    List<int> result = List.generate(wordLength, (_) => 1); // Start with all wrong (1)

    for (int i = 0; i < wordLength; i++) {
      if (guess[i] == targetWord[i]) {
        result[i] = 3; // Correct position (green)
        targetLetterCount[guess[i]] = targetLetterCount[guess[i]]! - 1;
      }
    }

    // Second pass: Mark wrong positions (yellow)
    for (int i = 0; i < wordLength; i++) {
      if (result[i] != 3) { // Not already green
        String letter = guess[i];
        if (targetLetterCount.containsKey(letter) && targetLetterCount[letter]! > 0) {
          result[i] = 2; // Wrong position (yellow)
          targetLetterCount[letter] = targetLetterCount[letter]! - 1;
        }
      }
    }

    // Update the color grid and keyboard colors
    setState(() {
      colorGrid[currentRow] = result;

      // Update keyboard colors - only upgrade, never downgrade
      // Priority: green (3) > yellow (2) > gray (1) > default (0)
      for (int i = 0; i < wordLength; i++) {
        String letter = guess[i];
        int currentColor = keyboardColors[letter] ?? 0;
        int newColor = result[i];

        // Only update if new color is "better" (higher priority)
        if (newColor == 3) {
          // Green always wins
          keyboardColors[letter] = 3;
        } else if (newColor == 2 && currentColor != 3) {
          // Yellow only if not already green
          keyboardColors[letter] = 2;
        } else if (newColor == 1 && currentColor == 0) {
          // Gray only if not yet colored
          keyboardColors[letter] = 1;
        }
      }
    });
  }

  // Get color from color code
  Color _getColorFromCode(int code) {
    switch (code) {
      case 3:
        return Colors.green; // Correct position
      case 2:
        return Colors.amber[700]!; // Wrong position (yellow/amber)
      case 1:
        return Colors.grey[700]!; // Wrong letter
      default:
        return Colors.grey[900]!; // Default/empty
    }
  }

  // Get keyboard key color from color code
  Color _getKeyboardColorFromCode(int code) {
    switch (code) {
      case 3:
        return Colors.green; // Correct position
      case 2:
        return Colors.amber[700]!; // Wrong position (yellow/amber)
      case 1:
        return Colors.grey[700]!; // Wrong letter
      default:
        return Colors.grey[300]!; // Default keyboard color
    }
  }

  // Show game end dialog
  void _showGameEndDialog(bool won) {
    // Save stats only once per game
    if (!_statsSaved) {
      _statsSaved = true;
      _saveGameStats(won);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          children: [
            Text(
              won ? '🎉' : '😢',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 8),
            Text(
              won ? 'Parabéns!' : 'Fim de jogo',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              won
                  ? 'Acertaste a palavra em ${currentRow + 1} tentativa${currentRow > 0 ? 's' : ''}!'
                  : 'A palavra era:',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            if (!won) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  targetWord,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_authService.currentUser != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green[400], size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Estatísticas guardadas',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[400],
                    ),
                  ),
                ],
              ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, '/stats');
            },
            icon: const Icon(Icons.bar_chart_rounded),
            label: const Text('Estatísticas'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _resetGame();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Jogar Novamente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Save game stats to Firebase
  Future<void> _saveGameStats(bool won) async {
    final attempts = currentRow + 1; // currentRow is 0-indexed

    try {
      await _authService.updateUserStats(
        won: won,
        attempts: attempts,
      );
      print('✅ Estatísticas do jogo salvas');
    } catch (e) {
      print('❌ Erro ao salvar estatísticas: $e');
    }
  }

  // Reset the game
  void _resetGame() {
    setState(() {
      grid = List.generate(
        maxAttempts,
        (_) => List.generate(wordLength, (_) => ''),
      );
      colorGrid = List.generate(
        maxAttempts,
        (_) => List.generate(wordLength, (_) => 0),
      );
      currentRow = 0;
      currentCol = 0;
      gameOver = false;
      won = false;
      keyboardColors = {};
      _statsSaved = false;
      _selectDailyWord();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Game Grid - Responsive letter boxes
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate box size based on available width
              // 5 boxes with margins (6px each side = 12px per box)
              final double maxBoxWidth = (constraints.maxWidth - (5 * 6)) / 5;
              // Limit the size for larger screens
              final double boxSize = maxBoxWidth.clamp(40.0, 62.0);

              return Column(
                children: List.generate(maxAttempts, (rowIndex) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(wordLength, (colIndex) {
                      return _letraCaixa(
                        grid[rowIndex][colIndex],
                        _getColorFromCode(colorGrid[rowIndex][colIndex]),
                        boxSize,
                      );
                    }),
                  );
                }),
              );
            },
          ),
        ),
        Expanded(child: Container()),
        // Responsive Keyboard
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate key sizes based on available width
              final double keySpacing = 4.0;
              final int keysInTopRow = 10;
              final double availableWidth = constraints.maxWidth - (keySpacing * (keysInTopRow + 1));
              final double keyWidth = availableWidth / keysInTopRow;
              final double keyHeight = keyWidth * 1.3;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: Q W E R T Y U I O P
                  _buildKeyboardRow(
                    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
                    keyWidth,
                    keyHeight,
                    keySpacing,
                    _addLetter,
                  ),
                  SizedBox(height: keySpacing),
                  // Row 2: A S D F G H J K L
                  _buildKeyboardRow(
                    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
                    keyWidth,
                    keyHeight,
                    keySpacing,
                    _addLetter,
                  ),
                  SizedBox(height: keySpacing),
                  // Row 3: ENTER Z X C V B N M ⌫
                  _buildBottomKeyboardRow(
                    keyWidth,
                    keyHeight,
                    keySpacing,
                    _addLetter,
                    _removeLetter,
                    _submitGuess,
                  ),
                ],
              );
            },
          ),
        ),
        SizedBox(height: 4),
      ],
    );
  }

  Widget _buildKeyboardRow(
    List<String> letters,
    double keyWidth,
    double keyHeight,
    double spacing,
    Function(String) onKeyPressed,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: letters.map((letter) {
        int colorCode = keyboardColors[letter] ?? 0;
        Color bgColor = _getKeyboardColorFromCode(colorCode);
        Color textColor = colorCode == 0 ? Colors.black : Colors.white;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing / 2),
          child: SizedBox(
            width: keyWidth,
            height: keyHeight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: bgColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: () => onKeyPressed(letter),
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: keyWidth * 0.45,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomKeyboardRow(
    double keyWidth,
    double keyHeight,
    double spacing,
    Function(String) onKeyPressed,
    VoidCallback onBackspace,
    VoidCallback onEnter,
  ) {
    final List<String> middleLetters = ['Z', 'X', 'C', 'V', 'B', 'N', 'M'];
    final double wideKeyWidth = keyWidth * 1.5;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ENTER key
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing / 2),
          child: SizedBox(
            width: wideKeyWidth,
            height: keyHeight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: onEnter,
              child: Text(
                'ENTER',
                style: TextStyle(
                  fontSize: keyWidth * 0.32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        // Middle letters with colors
        ...middleLetters.map((letter) {
          int colorCode = keyboardColors[letter] ?? 0;
          Color bgColor = _getKeyboardColorFromCode(colorCode);
          Color textColor = colorCode == 0 ? Colors.black : Colors.white;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing / 2),
            child: SizedBox(
              width: keyWidth,
              height: keyHeight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: bgColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onPressed: () => onKeyPressed(letter),
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: keyWidth * 0.45,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),
          );
        }),
        // Backspace key
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing / 2),
          child: SizedBox(
            width: wideKeyWidth,
            height: keyHeight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: onBackspace,
              child: Icon(
                Icons.backspace_outlined,
                size: keyWidth * 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Responsive letter box widget
Widget _letraCaixa(String letra, Color cor, double size) {
  return Container(
    width: size,
    height: size,
    margin: EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: cor,
      border: Border.all(color: Colors.grey),
      borderRadius: BorderRadius.circular(2),
    ),
    child: Center(
      child: Text(
        letra,
        style: TextStyle(
          fontSize: size * 0.5,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
  );
}
