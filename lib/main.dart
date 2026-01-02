import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:projeto_prog_mobile_wordle/screens/teste_firebase_simples.dart';
import 'package:projeto_prog_mobile_wordle/screens/admin_painel.dart';
import 'package:projeto_prog_mobile_wordle/screens/login_screen.dart';
import 'package:projeto_prog_mobile_wordle/screens/stats_screen.dart';

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
        '/teste': (context) => const TesteFirebaseSimples(),
        '/admin': (context) => const AdminPainel(),
        '/login': (context) => LoginScreen(),
        '/stats': (context) => StatsScreen(),
      },
    );
  }
}

// Tela inicial do Wordle
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        title: Text('Wordle'),
        backgroundColor: Colors.grey[600],
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart),
            tooltip: 'Estatísticas',
            onPressed: () {
              Navigator.pushNamed(context, '/stats');
            },
          ),
          IconButton(
            icon: Icon(Icons.cloud),
            tooltip: 'Testar Firebase',
            onPressed: () {
              Navigator.pushNamed(context, '/teste');
            },
          ),
          IconButton(
            icon: Icon(Icons.admin_panel_settings),
            tooltip: 'Painel Admin',
            onPressed: () {
              Navigator.pushNamed(context, '/admin');
            },
          ),
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
  // Game state
  static const int maxAttempts = 6;
  static const int wordLength = 5;

  // Grid of letters - 6 rows x 5 columns
  List<List<String>> grid = List.generate(
    maxAttempts,
    (_) => List.generate(wordLength, (_) => ''),
  );

  // Current position
  int currentRow = 0;
  int currentCol = 0;

  // Add a letter to the current position
  void _addLetter(String letter) {
    if (currentRow < maxAttempts && currentCol < wordLength) {
      setState(() {
        grid[currentRow][currentCol] = letter;
        currentCol++;
      });
    }
  }

  // Remove the last letter (backspace)
  void _removeLetter() {
    if (currentCol > 0) {
      setState(() {
        currentCol--;
        grid[currentRow][currentCol] = '';
      });
    }
  }

  // Submit the current guess (ENTER)
  void _submitGuess() {
    if (currentCol == wordLength) {
      // Move to next row
      setState(() {
        currentRow++;
        currentCol = 0;
      });
    }
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
                        Colors.grey[900]!,
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
      children: letters.map((letter) => Padding(
        padding: EdgeInsets.symmetric(horizontal: spacing / 2),
        child: SizedBox(
          width: keyWidth,
          height: keyHeight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
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
              ),
            ),
          ),
        ),
      )).toList(),
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
        // Middle letters
        ...middleLetters.map((letter) => Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing / 2),
          child: SizedBox(
            width: keyWidth,
            height: keyHeight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
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
                ),
              ),
            ),
          ),
        )),
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
