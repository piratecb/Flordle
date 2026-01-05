import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

// Theme notifier to manage theme state across the app
class ThemeNotifier extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  ThemeNotifier() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey);
    if (themeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == themeString,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.toString());
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.dark || (_themeMode == ThemeMode.system && isDarkMode)) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}

// Global theme notifier instance
final themeNotifier = ThemeNotifier();

// App themes - Custom Color Palette
// Light: #6d9ac7, #1269cc, #51eefc, #ffffff, #303030
// Dark: Uses shades of grey instead of white
// Font: Nunito (readable, friendly, modern)
class AppThemes {
  // Custom colors
  static const Color primaryBlue = Color(0xFF1269CC);
  static const Color softBlue = Color(0xFF6D9AC7);
  static const Color accentCyan = Color(0xFF51EEFC);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkGrey = Color(0xFF303030);

  // Dark theme shades
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color darkSurface = Color(0xFF252525);
  static const Color darkCard = Color(0xFF2D2D2D);
  static const Color lightGrey = Color(0xFFB0B0B0);

  static ThemeData get darkTheme {
    final baseTheme = ThemeData(brightness: Brightness.dark);
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      textTheme: baseTheme.textTheme.apply(fontFamily: 'Nunito'),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: lightGrey),
        titleTextStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: lightGrey,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: accentCyan,
        tertiary: softBlue,
        surface: darkSurface,
        onSurface: lightGrey,
        onPrimary: pureWhite,
        onSecondary: darkGrey,
      ),
      cardTheme: const CardThemeData(
        color: darkCard,
      ),
      iconTheme: const IconThemeData(color: lightGrey),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: pureWhite,
          textStyle: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentCyan,
          textStyle: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    final baseTheme = ThemeData(brightness: Brightness.light);
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: pureWhite,
      textTheme: baseTheme.textTheme.apply(fontFamily: 'Nunito'),
      appBarTheme: AppBarTheme(
        backgroundColor: softBlue.withValues(alpha: 0.3),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: darkGrey),
        titleTextStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: darkGrey,
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: accentCyan,
        tertiary: softBlue,
        surface: pureWhite,
        onSurface: darkGrey,
        onPrimary: pureWhite,
        onSecondary: darkGrey,
      ),
      cardTheme: CardThemeData(
        color: softBlue.withValues(alpha: 0.15),
      ),
      iconTheme: const IconThemeData(color: darkGrey),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: pureWhite,
          textStyle: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          textStyle: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

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
    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeNotifier.themeMode,
          initialRoute: '/',
          routes: {
            '/': (context) => const HomeScreen(),
            '/login': (context) => LoginScreen(),
            '/stats': (context) => StatsScreen(),
          },
        );
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

  void _showHowToPlayDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.help_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('Como jogar'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'O flordle é como o jogo da forca, mas sem o boneco. Tenta adivinhar qual é a palavra de hoje escrevendo uma palavra e descobrindo letras aos poucos.',
                ),
                const SizedBox(height: 16),
                _buildColorHint(
                  context,
                  Colors.green,
                  'Letra verde:',
                  'a letra está na palavra e está no local correto',
                ),
                const SizedBox(height: 8),
                _buildColorHint(
                  context,
                  Colors.amber,
                  'Letra amarela:',
                  'a letra está na palavra mas não está no local correto',
                ),
                const SizedBox(height: 8),
                _buildColorHint(
                  context,
                  Colors.grey,
                  'Letra cinzenta:',
                  'a letra não está na palavra.',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tens 6 tentativas para descobrir, boa sorte!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Nota: algumas palavras usam a mesma letra duas vezes, por isso tem atenção!',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendi!'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildColorHint(BuildContext context, Color color, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              children: [
                TextSpan(
                  text: '$title ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        leading: _selectedMode != null
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: iconColor),
                tooltip: 'Voltar ao menu',
                onPressed: _backToMenu,
              )
            : IconButton(
                icon: Icon(Icons.info_outline, color: iconColor),
                tooltip: 'Como jogar',
                onPressed: () => _showHowToPlayDialog(context),
              ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'F',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              'L',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            Text(
              'ORDLE',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: iconColor,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: isDark ? Colors.amber[300] : Colors.orange[400],
            ),
            tooltip: isDark ? 'Mudar para tema claro' : 'Mudar para tema escuro',
            onPressed: () {
              themeNotifier.toggleTheme();
            },
          ),
          StreamBuilder(
            stream: _authService.authStateChanges,
            builder: (context, snapshot) {
              final user = _authService.currentUser;
              final isLoggedIn = user != null && !user.isAnonymous;

              // Show stats button only when in game mode and not logged in
              if (_selectedMode != null && !isLoggedIn) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.bar_chart_rounded, color: iconColor),
                      tooltip: 'Estatísticas',
                      onPressed: () {
                        Navigator.pushNamed(context, '/stats');
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.account_circle_outlined,
                        color: iconColor,
                        size: 28,
                      ),
                      tooltip: 'Entrar',
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                    ),
                  ],
                );
              }

              return IconButton(
                icon: Icon(
                  isLoggedIn ? Icons.account_circle : Icons.account_circle_outlined,
                  color: isLoggedIn ? Theme.of(context).colorScheme.primary : iconColor,
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
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Escolhe o modo de jogo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 48),

            // Modo Diário
            _buildModeCard(
              icon: Icons.calendar_today_rounded,
              title: 'Palavra do Dia',
              subtitle: 'Uma palavra por dia para todos os jogadores',
              color: Theme.of(context).colorScheme.primary,
              onTap: () => _selectMode(GameMode.daily),
            ),

            const SizedBox(height: 16),

            // Modo Ilimitado
            _buildModeCard(
              icon: Icons.all_inclusive_rounded,
              title: 'Modo Ilimitado',
              subtitle: 'Joga quantas vezes quiseres com palavras aleatórias',
              color: Theme.of(context).colorScheme.secondary,
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

            const SizedBox(height: 16),

            // Modo Sorte
            _buildModeCard(
              icon: Icons.casino_rounded,
              title: 'Modo Sorte',
              subtitle: 'Obtém letras aleatórias e forma palavras com elas',
              color: Colors.purple[600]!,
              onTap: () => _selectMode(GameMode.luck),
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
    final cardColor = Theme.of(context).cardTheme.color;
    final subtitleColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[400]
        : Colors.grey[600];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
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
                      color: subtitleColor,
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
enum GameMode { daily, unlimited, rapidFire, luck }

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

  // Luck mode state
  Set<String> _luckAvailableLetters = {}; // Currently available letters
  Set<String> _luckPermanentLetters = {}; // Letters that are permanently available (correct ones)
  static const int luckLettersPerRoll = 10; // Number of letters per roll
  bool _hasRolledThisRound = false; // Track if player has rolled this round

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

  // Luck mode methods
  void _rollLuckLetters() {
    if (_hasRolledThisRound && widget.gameMode == GameMode.luck) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Já obtiveste letras nesta ronda! Submete a tua tentativa primeiro.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final random = Random();
    const allLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

    // Start with permanent letters (correct ones from previous rounds)
    Set<String> newLetters = Set.from(_luckPermanentLetters);

    // Always include ALL letters from the target word to guarantee it's solvable
    for (String letter in targetWord.split('')) {
      newLetters.add(letter);
    }

    // Fill the rest with random letters until we have luckLettersPerRoll total
    while (newLetters.length < luckLettersPerRoll + _luckPermanentLetters.length) {
      String randomLetter = allLetters[random.nextInt(allLetters.length)];
      newLetters.add(randomLetter);
    }

    // Double-check that at least one valid word can be formed
    // (should always be true since we include target word letters)
    if (!_canFormAnyValidWord(newLetters)) {
      // Fallback: add more letters from a random valid word
      List<String> validWords = WordList.words.where((word) {
        return _canFormWordWithLetters(word, newLetters);
      }).toList();

      if (validWords.isEmpty) {
        // Pick a random word and add its letters
        String randomWord = WordList.words[random.nextInt(WordList.words.length)];
        for (String letter in randomWord.split('')) {
          newLetters.add(letter);
        }
      }
    }

    setState(() {
      _luckAvailableLetters = newLetters;
      _hasRolledThisRound = true;
    });
  }

  // Check if any valid word can be formed with the given letters
  bool _canFormAnyValidWord(Set<String> availableLetters) {
    for (String word in WordList.words) {
      if (_canFormWordWithLetters(word, availableLetters)) {
        return true;
      }
    }
    return false;
  }

  // Check if a specific word can be formed with the given letters
  bool _canFormWordWithLetters(String word, Set<String> availableLetters) {
    // Count available letters
    Map<String, int> letterCount = {};
    for (String letter in availableLetters) {
      letterCount[letter] = (letterCount[letter] ?? 0) + 1;
    }

    // Check if word can be formed (considering letter frequency)
    Map<String, int> neededCount = {};
    for (String letter in word.split('')) {
      neededCount[letter] = (neededCount[letter] ?? 0) + 1;
    }

    // For our simple case, just check if all unique letters exist
    // (since we're using a Set, each letter appears once)
    for (String letter in word.split('')) {
      if (!availableLetters.contains(letter)) {
        return false;
      }
    }
    return true;
  }

  // Get list of valid words that can be formed with current available letters
  List<String> _getFormableWords() {
    Set<String> allAvailable = {..._luckAvailableLetters, ..._luckPermanentLetters};
    return WordList.words.where((word) {
      return _canFormWordWithLetters(word, allAvailable);
    }).toList();
  }

  bool _isLetterAvailableInLuckMode(String letter) {
    if (widget.gameMode != GameMode.luck) return true;
    return _luckAvailableLetters.contains(letter) || _luckPermanentLetters.contains(letter);
  }

  void _updateLuckPermanentLetters() {
    // Check the last submitted row for correct letters (green)
    int lastRow = currentRow > 0 ? currentRow - 1 : 0;
    for (int i = 0; i < wordLength; i++) {
      if (colorGrid[lastRow][i] == 3) { // Green = correct
        _luckPermanentLetters.add(grid[lastRow][i]);
      }
    }
  }

  // Add a letter to the current position
  void _addLetter(String letter) {
    if (gameOver) return;

    // Check if letter is available in Luck mode
    if (widget.gameMode == GameMode.luck && !_isLetterAvailableInLuckMode(letter)) {
      return; // Letter not available, do nothing
    }

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

    // In Luck mode, require rolling letters first
    if (widget.gameMode == GameMode.luck && !_hasRolledThisRound && _luckAvailableLetters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clica em "Obter Letras" primeiro!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.purple,
        ),
      );
      return;
    }

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

      // Update permanent letters for Luck mode (before checking win)
      if (widget.gameMode == GameMode.luck) {
        _updateLuckPermanentLetters();
        _hasRolledThisRound = false; // Allow rolling again for next round
      }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (code) {
      case 3:
        return Colors.green; // Correct position (classic green)
      case 2:
        return Colors.amber[700]!; // Wrong position (classic yellow/amber)
      case 1:
        return isDark ? Colors.grey[700]! : Colors.grey[600]!; // Wrong letter (darker in light mode)
      default:
        return isDark ? Colors.grey[900]! : Colors.grey[500]!; // Default/empty (darker in light mode)
    }
  }

  // Get keyboard key color from color code
  Color _getKeyboardColorFromCode(int code) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (code) {
      case 3:
        return Colors.green; // Correct position (keep classic green)
      case 2:
        return Colors.amber[700]!; // Wrong position (keep classic yellow/amber)
      case 1:
        return isDark ? Colors.grey[700]! : Colors.grey[600]!; // Wrong letter (darker in light mode)
      default:
        return isDark ? Colors.grey[300]! : Colors.grey[400]!; // Default keyboard color
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
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final dialogBg = isDark ? Colors.grey[850] : Colors.grey[100];
        final textColor = isDark ? Colors.white : Colors.black87;
        final subtextColor = isDark ? Colors.white70 : Colors.black54;

        return AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            children: [
              Icon(
                won ? Icons.celebration_rounded : Icons.sentiment_dissatisfied_rounded,
                size: 48,
                color: won ? Colors.amber[400] : Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                won ? 'Parabéns!' : 'Fim de jogo',
                style: TextStyle(
                  color: textColor,
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
                style: TextStyle(fontSize: 16, color: subtextColor),
                textAlign: TextAlign.center,
              ),
              if (!won) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    targetWord,
                    style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
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
                  Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Estatísticas guardadas',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
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
          else if (widget.gameMode == GameMode.luck)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
              icon: const Icon(Icons.casino_rounded),
              label: const Text('Jogar Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
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
      );
      },
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

      // Reset Luck mode state
      _luckAvailableLetters = {};
      _luckPermanentLetters = {};
      _hasRolledThisRound = false;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if we're in landscape mode (width > height)
        final isLandscape = constraints.maxWidth > constraints.maxHeight;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top section with banners and grid
                Column(
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
                                ? 'Acertaste em $currentRow tentativa${currentRow > 1 ? 's' : ''}! Volta amanhã.'
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
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timer_rounded,
                            color: _secondsRemaining <= 5
                                ? Colors.red[400]
                                : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$_secondsRemaining',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _secondsRemaining <= 5
                                  ? Colors.red[400]
                                  : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            's',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Luck mode UI - Get Letters button and available letters display
                  if (widget.gameMode == GameMode.luck && !gameOver)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                      child: Column(
                        children: [
                          // Get Letters Button
                          ElevatedButton.icon(
                            onPressed: _hasRolledThisRound ? null : _rollLuckLetters,
                            icon: Icon(
                              Icons.casino_rounded,
                              color: _hasRolledThisRound ? Colors.grey[600] : Colors.white,
                              size: 18,
                            ),
                            label: Text(
                              _hasRolledThisRound ? 'Já obtiveste letras' : 'Obter Letras',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _hasRolledThisRound ? Colors.grey[600] : Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _hasRolledThisRound ? Colors.grey[800] : Colors.purple[600],
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Display available letters
                          if (_luckAvailableLetters.isNotEmpty || _luckPermanentLetters.isNotEmpty)
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              alignment: WrapAlignment.center,
                              children: [
                                // Show permanent letters (green) first
                                ..._luckPermanentLetters.map((letter) => Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.green[300]!, width: 1),
                                  ),
                                  child: Center(
                                    child: Text(
                                      letter,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )),
                                // Show temporary available letters (purple)
                                ..._luckAvailableLetters
                                    .where((l) => !_luckPermanentLetters.contains(l))
                                    .map((letter) => Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.purple[600],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Center(
                                    child: Text(
                                      letter,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )),
                              ],
                            )
                          else
                            Text(
                              'Clica em "Obter Letras" para começar!',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          // Show hint about formable words
                          if (_luckAvailableLetters.isNotEmpty || _luckPermanentLetters.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Builder(
                                builder: (context) {
                                  int formableCount = _getFormableWords().length;
                                  return Text(
                                    'Podes formar $formableCount palavra${formableCount != 1 ? 's' : ''} válida${formableCount != 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: formableCount > 0 ? Colors.green[400] : Colors.red[400],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  // Game Grid - Responsive letter boxes
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: isLandscape ? 4.0 : 6.0,
                    ),
                    child: LayoutBuilder(
                      builder: (context, gridConstraints) {
                        // Calculate box size based on available width
                        // 5 boxes with margins (6px each side = 12px per box)
                        final double maxBoxWidth = (gridConstraints.maxWidth - (5 * 6)) / 5;
                        // Smaller boxes in landscape mode
                        final double boxSize = isLandscape
                            ? maxBoxWidth.clamp(32.0, 44.0)
                            : maxBoxWidth.clamp(36.0, 56.0);

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
                  ],
                ),
                // Bottom section with keyboard
                Column(
                  children: [
                    // Responsive Keyboard (escondido se jogo diário completado)
                    if (!(widget.gameMode == GameMode.daily && _dailyGameCompleted))
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: isLandscape ? 2.0 : 4.0,
                        ),
                        child: LayoutBuilder(
                          builder: (context, keyboardConstraints) {
                            // Calculate key sizes based on available width with max limit
                            final double keySpacing = 4.0;
                            final int keysInTopRow = 10;
                            final double availableWidth = keyboardConstraints.maxWidth - (keySpacing * (keysInTopRow + 1));
                            // Use all available space, with max limit of 64px per key
                            final double calculatedKeyWidth = availableWidth / keysInTopRow;
                            final double keyWidth = calculatedKeyWidth.clamp(28.0, 64.0);
                            final double keyHeight = keyWidth * 1.5;

                            // Center the keyboard by calculating total width
                            final double totalKeyboardWidth = (keyWidth * keysInTopRow) + (keySpacing * (keysInTopRow + 1));

                            return Center(
                              child: SizedBox(
                                width: totalKeyboardWidth,
                                child: Column(
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
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    SizedBox(height: isLandscape ? 4 : 8),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
        bool isAvailableInLuckMode = _isLetterAvailableInLuckMode(letter);
        bool isLuckMode = widget.gameMode == GameMode.luck;

        // In Luck mode, show unavailable letters as very dark/hidden
        Color bgColor;
        Color textColor;

        if (isLuckMode && !isAvailableInLuckMode) {
          // Unavailable letter in Luck mode - make it almost invisible
          bgColor = Colors.grey[900]!;
          textColor = Colors.grey[800]!;
        } else if (isLuckMode && _luckPermanentLetters.contains(letter)) {
          // Permanent letter (correct from previous rounds)
          bgColor = Colors.green;
          textColor = Colors.white;
        } else if (isLuckMode && _luckAvailableLetters.contains(letter)) {
          // Temporary available letter
          bgColor = Colors.purple[600]!;
          textColor = Colors.white;
        } else {
          // Normal mode or default
          bgColor = _getKeyboardColorFromCode(colorCode);
          textColor = colorCode == 0 ? Colors.black : Colors.white;
        }

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
              onPressed: (isLuckMode && !isAvailableInLuckMode) ? null : () => onKeyPressed(letter),
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
          bool isAvailableInLuckMode = _isLetterAvailableInLuckMode(letter);
          bool isLuckMode = widget.gameMode == GameMode.luck;

          // In Luck mode, show unavailable letters as very dark/hidden
          Color bgColor;
          Color textColor;

          if (isLuckMode && !isAvailableInLuckMode) {
            // Unavailable letter in Luck mode
            bgColor = Colors.grey[900]!;
            textColor = Colors.grey[800]!;
          } else if (isLuckMode && _luckPermanentLetters.contains(letter)) {
            // Permanent letter (correct from previous rounds)
            bgColor = Colors.green;
            textColor = Colors.white;
          } else if (isLuckMode && _luckAvailableLetters.contains(letter)) {
            // Temporary available letter
            bgColor = Colors.purple[600]!;
            textColor = Colors.white;
          } else {
            // Normal mode or default
            bgColor = _getKeyboardColorFromCode(colorCode);
            textColor = colorCode == 0 ? Colors.black : Colors.white;
          }

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
                onPressed: (isLuckMode && !isAvailableInLuckMode) ? null : () => onKeyPressed(letter),
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
    margin: const EdgeInsets.all(2),
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
