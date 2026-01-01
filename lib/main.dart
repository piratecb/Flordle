import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

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
      home: Scaffold(
        backgroundColor: Colors.grey[850],
        appBar: AppBar(
          title: Text('Wordle'),
          backgroundColor: Colors.grey[600],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  Row( //Quadrados das letras
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      letraCaixa('', Colors.grey[900]!),
                      letraCaixa('', Colors.grey[900]!),
                      letraCaixa('', Colors.grey[900]!),
                      letraCaixa('', Colors.grey[900]!),
                      letraCaixa('', Colors.grey[900]!),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      letraCaixa('', Colors.grey[900]!),
                      letraCaixa('', Colors.grey[900]!),
                      letraCaixa('', Colors.grey[900]!),
                      letraCaixa('', Colors.grey[900]!),
                      letraCaixa('', Colors.grey[900]!),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      letraCaixa('', Colors.grey[900]!),
                      letraCaixa('', Colors.grey[900]!),
                      letraCaixa('', Colors.grey[900]!),
                      letraCaixa('', Colors.grey[900]!),
                      letraCaixa('', Colors.grey[900]!),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      letraCaixa('', Colors.grey[900]!),
                      letraCaixa('', Colors.grey[900]!),
                      letraCaixa('', Colors.grey[900]!),
                      letraCaixa('', Colors.grey[900]!),
                      letraCaixa('', Colors.grey[900]!),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      letraCaixa('', Colors.grey[900]!),
                      letraCaixa('', Colors.grey[900]!),
                      letraCaixa('', Colors.grey[900]!),
                      letraCaixa('', Colors.grey[900]!),
                      letraCaixa('', Colors.grey[900]!),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      letraCaixa('', Colors.grey[900]!),
                      letraCaixa('', Colors.grey[900]!),
                      letraCaixa('', Colors.grey[900]!),
                      letraCaixa('', Colors.grey[900]!),
                      letraCaixa('', Colors.grey[900]!),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(child: Container()),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row( //Teclado
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      teclaBotao('Q'),
                      teclaBotao('W'),
                      teclaBotao('E'),
                      teclaBotao('R'),
                      teclaBotao('T'),
                      teclaBotao('Y'),
                      teclaBotao('U'),
                      teclaBotao('I'),
                      teclaBotao('O'),
                      teclaBotao('P'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      teclaBotao('A'),
                      teclaBotao('S'),
                      teclaBotao('D'),
                      teclaBotao('F'),
                      teclaBotao('G'),
                      teclaBotao('H'),
                      teclaBotao('J'),
                      teclaBotao('K'),
                      teclaBotao('L'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      teclaBotaoGrande('ENTER'),
                      teclaBotao('Z'),
                      teclaBotao('X'),
                      teclaBotao('C'),
                      teclaBotao('V'),
                      teclaBotao('B'),
                      teclaBotao('N'),
                      teclaBotao('M'),
                      teclaBotaoGrande('⌫'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Container letraCaixa(String letra, Color cor) { // "CSS" das caixas de letras
  return Container(
    width: 50,
    height: 50,
    margin: EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: cor,
      border: Border.all(color: Colors.grey),
    ),
    child: Center(
      child: Text(
        letra,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ),
  );
}

Padding teclaBotao(String letra) { // "CSS" das teclas pequenas
  return Padding(
    padding: const EdgeInsets.all(2.0),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(32, 42),
        padding: EdgeInsets.symmetric(horizontal: 4),
      ),
      onPressed: () {},
      child: Text(letra, style: TextStyle(fontSize: 12)),
    ),
  );
}

Padding teclaBotaoGrande(String texto) { // "CSS" das teclas grandes
  return Padding(
    padding: const EdgeInsets.all(2.0),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(56, 42),
        padding: EdgeInsets.symmetric(horizontal: 4),
      ),
      onPressed: () {},
      child: Text(texto, style: TextStyle(fontSize: 12)),
    ),
  );
}
