import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:async';
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
        '/': (context) => const HomeScreen(),
        '/login': (context) => LoginScreen(),
        '/stats': (context) => StatsScreen(),
      },
    );
  }
}

// Tela inicial do Wordle
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  GameMode? _selectedMode;

  void _selectMode(GameMode mode) {
    setState(() {
      _selectedMode = mode;
    });
  }

  void _backToMenu() {
    setState(() {
      _selectedMode = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: _selectedMode != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                tooltip: 'Voltar ao menu',
                onPressed: _backToMenu,
              )
            : IconButton(
                icon: const Icon(Icons.bar_chart_rounded, color: Colors.white),
                tooltip: 'Estatísticas',
                onPressed: () {
                  Navigator.pushNamed(context, '/stats');
                },
              ),
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
        actions: [
          if (_selectedMode != null)
            IconButton(
              icon: const Icon(Icons.bar_chart_rounded, color: Colors.white),
              tooltip: 'Estatísticas',
              onPressed: () {
                Navigator.pushNamed(context, '/stats');
              },
            ),
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
        child: _selectedMode == null
            ? _buildModeSelection()
            : WordleBody(key: ValueKey(_selectedMode), gameMode: _selectedMode!),
      ),
    );
  }

  Widget _buildModeSelection() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo/Título
            Text(
              '🎯',
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            const Text(
              'Escolhe o modo de jogo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 48),

            // Modo Diário
            _buildModeCard(
              icon: Icons.calendar_today_rounded,
              title: 'Palavra do Dia',
              subtitle: 'Uma palavra por dia para todos os jogadores',
              color: Colors.green[600]!,
              onTap: () => _selectMode(GameMode.daily),
            ),

            const SizedBox(height: 16),

            // Modo Ilimitado
            _buildModeCard(
              icon: Icons.all_inclusive_rounded,
              title: 'Modo Ilimitado',
              subtitle: 'Joga quantas vezes quiseres com palavras aleatórias',
              color: Colors.amber[700]!,
              onTap: () => _selectMode(GameMode.unlimited),
            ),

            const SizedBox(height: 16),

            // Modo Rapid Fire
            _buildModeCard(
              icon: Icons.timer_rounded,
              title: 'Modo Rapid Fire',
              subtitle: 'Adivinha rápido! Tens tempo limitado por tentativa',
              color: Colors.red[600]!,
              onTap: () => _selectMode(GameMode.rapidFire),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(128), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}

// Enum para modo de jogo
enum GameMode { daily, unlimited, rapidFire }

// Corpo do jogo Wordle
class WordleBody extends StatefulWidget {
  final GameMode gameMode;

  const WordleBody({super.key, this.gameMode = GameMode.daily});

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

  // Daily game state
  bool _dailyGameCompleted = false;
  bool _isLoading = true;

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

  // Rapid Fire mode timer
  Timer? _rapidFireTimer;
  int _secondsRemaining = 0;
  static const int rapidFireTimeLimit = 20; // seconds per guess

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  Future<void> _initGame() async {
    _selectWord();

    if (widget.gameMode == GameMode.daily) {
      await _loadDailyGameState();
    }

    // Start timer for Rapid Fire mode
    if (widget.gameMode == GameMode.rapidFire) {
      _startRapidFireTimer();
    }

    setState(() {
      _isLoading = false;
    });
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return 'daily_game_${now.year}_${now.month}_${now.day}';
  }

  Future<void> _loadDailyGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _getTodayKey();
    final savedState = prefs.getString(todayKey);

    if (savedState != null) {
      final Map<String, dynamic> state = jsonDecode(savedState);

      setState(() {
        _dailyGameCompleted = state['completed'] ?? false;
        won = state['won'] ?? false;
        currentRow = state['currentRow'] ?? 0;

        // Restaurar grid de letras
        if (state['grid'] != null) {
          List<dynamic> savedGrid = state['grid'];
          for (int i = 0; i < savedGrid.length && i < maxAttempts; i++) {
            List<dynamic> row = savedGrid[i];
            for (int j = 0; j < row.length && j < wordLength; j++) {
              grid[i][j] = row[j].toString();
            }
          }
        }

        // Restaurar cores do grid
        if (state['colorGrid'] != null) {
          List<dynamic> savedColorGrid = state['colorGrid'];
          for (int i = 0; i < savedColorGrid.length && i < maxAttempts; i++) {
            List<dynamic> row = savedColorGrid[i];
            for (int j = 0; j < row.length && j < wordLength; j++) {
              colorGrid[i][j] = row[j] as int;
            }
          }
        }

        // Restaurar cores do teclado
        if (state['keyboardColors'] != null) {
          Map<String, dynamic> savedKeyboard = state['keyboardColors'];
          savedKeyboard.forEach((key, value) {
            keyboardColors[key] = value as int;
          });
        }

        if (_dailyGameCompleted) {
          gameOver = true;
          _statsSaved = true; // Já foi salvo anteriormente
        }
      });
    }
  }

  Future<void> _saveDailyGameState() async {
    if (widget.gameMode != GameMode.daily) return;

    final prefs = await SharedPreferences.getInstance();
    final todayKey = _getTodayKey();

    final state = {
      'completed': gameOver,
      'won': won,
      'currentRow': currentRow,
      'grid': grid,
      'colorGrid': colorGrid,
      'keyboardColors': keyboardColors,
    };

    await prefs.setString(todayKey, jsonEncode(state));
  }

  // Select the word based on game mode
  void _selectWord() {
    if (widget.gameMode == GameMode.daily) {
      // Modo diário: usa a palavra do dia
      targetWord = WordList.getWordForDate(DateTime.now());
      print('🎯 Palavra do dia: $targetWord');
    } else {
      // Modo ilimitado/rapid fire: palavra aleatória
      final random = Random();
      final wordIndex = random.nextInt(WordList.words.length);
      targetWord = WordList.words[wordIndex];
      print('🎲 Palavra aleatória: $targetWord');
    }
  }

  // Rapid Fire timer methods
  void _startRapidFireTimer() {
    _cancelRapidFireTimer();
    _secondsRemaining = rapidFireTimeLimit;
    _rapidFireTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsRemaining--;
      });
      if (_secondsRemaining <= 0) {
        _onRapidFireTimeout();
      }
    });
  }

  void _cancelRapidFireTimer() {
    _rapidFireTimer?.cancel();
    _rapidFireTimer = null;
  }

  void _onRapidFireTimeout() {
    _cancelRapidFireTimer();

    if (gameOver) return;

    // Mark the current row as all wrong (gray) since time ran out
    setState(() {
      // Clear the current row letters (user didn't finish typing)
      for (int i = 0; i < wordLength; i++) {
        if (grid[currentRow][i].isEmpty) {
          grid[currentRow][i] = '-'; // placeholder for skipped
        }
        colorGrid[currentRow][i] = 1; // Mark as wrong
      }

      currentRow++;
      currentCol = 0;
    });

    // Check if game over
    if (currentRow >= maxAttempts) {
      setState(() {
        gameOver = true;
        won = false;
      });
      _showGameEndDialog(false);
    } else {
      // Start timer for next guess
      _startRapidFireTimer();

      // Show a quick notification that time ran out
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.timer_off, color: Colors.white),
              const SizedBox(width: 8),
              Text('Tempo esgotado! Tentativa ${currentRow} de $maxAttempts'),
            ],
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  void dispose() {
    _cancelRapidFireTimer();
    super.dispose();
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
        _cancelRapidFireTimer(); // Stop timer on win
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
        _cancelRapidFireTimer(); // Stop timer on loss
        setState(() {
          gameOver = true;
          won = false;
        });
        _showGameEndDialog(false);
      } else if (widget.gameMode == GameMode.rapidFire) {
        // Restart timer for next guess in Rapid Fire mode
        _startRapidFireTimer();
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
      _saveDailyGameState(); // Salva estado do jogo diário
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
          if (widget.gameMode == GameMode.unlimited)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Nova Palavra'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          else if (widget.gameMode == GameMode.rapidFire)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
                _startRapidFireTimer();
              },
              icon: const Icon(Icons.timer_rounded),
              label: const Text('Jogar Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Fechar'),
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
      _selectWord();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        // Banner para jogo diário completado
        if (widget.gameMode == GameMode.daily && _dailyGameCompleted)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: won ? Colors.green[700] : Colors.grey[700],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  won ? Icons.emoji_events : Icons.calendar_today,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  won
                      ? 'Acertaste em ${currentRow} tentativa${currentRow > 1 ? 's' : ''}! Volta amanhã.'
                      : 'Já jogaste hoje. Volta amanhã!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        // Rapid Fire timer display
        if (widget.gameMode == GameMode.rapidFire && !gameOver)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_rounded,
                  color: _secondsRemaining <= 5 ? Colors.red[400] : Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '$_secondsRemaining',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _secondsRemaining <= 5 ? Colors.red[400] : Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'segundos',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
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
        // Responsive Keyboard (escondido se jogo diário completado)
        if (!(widget.gameMode == GameMode.daily && _dailyGameCompleted))
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
