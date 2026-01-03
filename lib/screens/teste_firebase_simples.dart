import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple Firebase test screen to verify connection
class TesteFirebaseSimples extends StatefulWidget {
  const TesteFirebaseSimples({super.key});

  @override
  State<TesteFirebaseSimples> createState() => _TesteFirebaseSimplesState();
}

class _TesteFirebaseSimplesState extends State<TesteFirebaseSimples> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _status = 'Aguardando teste...';
  bool _isLoading = false;

  Future<void> _testarConexao() async {
    setState(() {
      _isLoading = true;
      _status = 'Testando conexão...';
    });

    try {
      // Tentar escrever um documento de teste
      await _firestore.collection('test').doc('connection_test').set({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Conexão bem-sucedida!',
      });

      // Tentar ler o documento
      DocumentSnapshot doc = await _firestore
          .collection('test')
          .doc('connection_test')
          .get();

      if (doc.exists) {
        setState(() {
          _status = '[OK] Conexão Firebase OK!\n\nDados: ${doc.data()}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = '[ERRO] Erro na conexão:\n$e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste Firebase'),
        backgroundColor: Colors.grey[600],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_circle,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 30),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _testarConexao,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Testar Conexão'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

