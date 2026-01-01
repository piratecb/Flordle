import 'package:flutter/material.dart';
import 'package:projeto_prog_mobile_wordle/services/firebase_service.dart';

/// Tela simples de teste Firebase que pode ser acessada diretamente
class TesteFirebaseSimples extends StatefulWidget {
  const TesteFirebaseSimples({super.key});

  @override
  State<TesteFirebaseSimples> createState() => _TesteFirebaseSimplesState();
}

class _TesteFirebaseSimplesState extends State<TesteFirebaseSimples> {
  final FirebaseService _firebase = FirebaseService();
  String _resultado = 'Aguardando...';
  bool _testando = false;

  @override
  void initState() {
    super.initState();
    // Testa automaticamente quando a tela abre
    Future.delayed(Duration(milliseconds: 500), () {
      _testar();
    });
  }

  Future<void> _testar() async {
    setState(() {
      _testando = true;
      _resultado = '🔄 Testando Firebase...\n\n';
    });

    try {
      // Teste 1: Seed palavras para os próximos 7 dias
      await _firebase.seedDailyWords();
      setState(() {
        _resultado += '✅ 1. Palavras seeded (7 dias)\n';
      });

      // Teste 2: Buscar palavra de hoje
      String? palavra = await _firebase.getTodayWord();
      setState(() {
        _resultado += '✅ 2. Palavra de hoje: $palavra\n';
      });

      // Teste 3: Salvar jogo
      await _firebase.saveGame(
        playerName: 'teste_usuario',
        word: palavra ?? 'CRANE',
        guesses: ['STARE', palavra ?? 'CRANE'],
        won: true,
        attempts: 2,
      );
      setState(() {
        _resultado += '✅ 3. Jogo salvo\n';
      });

      // Teste 4: Buscar estatísticas
      Map<String, dynamic>? stats = await _firebase.getPlayerStats('teste_usuario');
      setState(() {
        _resultado += '✅ 4. Stats: ${stats?['gamesPlayed']} jogos\n\n';
        _resultado += '🎉 FIRESTORE FUNCIONANDO!\n\n';
        _resultado += 'Verifique no console Firebase.';
      });
    } catch (e) {
      setState(() {
        _resultado = '❌ ERRO!\n\n';
        if (e.toString().contains('PERMISSION_DENIED')) {
          _resultado += 'Firestore não está habilitado.\n\n';
          _resultado += 'Ative no console Firebase.';
        } else {
          _resultado += 'Erro: $e';
        }
      });
    } finally {
      setState(() {
        _testando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 600),
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _testando ? Icons.hourglass_empty : Icons.cloud_done,
                size: 100,
                color: _testando ? Colors.orange : Colors.green,
              ),
              SizedBox(height: 32),
              Text(
                'Teste Firebase',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'flordle-tpsi2526',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
              SizedBox(height: 48),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: Text(
                  _resultado,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 32),
              if (!_testando)
                ElevatedButton.icon(
                  onPressed: _testar,
                  icon: Icon(Icons.refresh),
                  label: Text('Testar Novamente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

