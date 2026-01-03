import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projeto_prog_mobile_wordle/models/game_model.dart';
import 'package:projeto_prog_mobile_wordle/models/player_stats.dart';

/// Admin panel to view game statistics and player data
class AdminPainel extends StatefulWidget {
  const AdminPainel({super.key});

  @override
  State<AdminPainel> createState() => _AdminPainelState();
}

class _AdminPainelState extends State<AdminPainel> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Administrativo'),
        backgroundColor: Colors.grey[600],
      ),
      body: Column(
        children: [
          // Tab selector
          Container(
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('Jogos', 0),
                ),
                Expanded(
                  child: _buildTabButton('Estatísticas', 1),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _selectedTab == 0 ? _buildGamesView() : _buildStatsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.blue : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildGamesView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('games')
          .orderBy('date', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('Nenhum jogo registrado ainda.'),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: Icon(
                  data['won'] == true ? Icons.check_circle : Icons.cancel,
                  color: data['won'] == true ? Colors.green : Colors.red,
                ),
                title: Text('${data['playerName']}'),
                subtitle: Text(
                  'Palavra: ${data['word']} | Tentativas: ${data['attempts']}',
                ),
                trailing: Text(data['date'] ?? 'N/A'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatsView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('statistics')
          .orderBy('gamesPlayed', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('Nenhuma estatística registrada ainda.'),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;

            int gamesPlayed = data['gamesPlayed'] ?? 0;
            int gamesWon = data['gamesWon'] ?? 0;
            int winRate = gamesPlayed > 0
                ? ((gamesWon / gamesPlayed) * 100).round()
                : 0;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ExpansionTile(
                leading: CircleAvatar(
                  child: Text('${data['playerName']?[0] ?? '?'}'.toUpperCase()),
                ),
                title: Text('${data['playerName']}'),
                subtitle: Text(
                  'Jogos: $gamesPlayed | Vitórias: $gamesWon | Taxa: $winRate%',
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sequência Atual: ${data['currentStreak'] ?? 0}'),
                        Text('Melhor Sequência: ${data['maxStreak'] ?? 0}'),
                        const SizedBox(height: 10),
                        const Text('Distribuição de Tentativas:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        ...((data['guessDistribution'] as Map? ?? {})
                            .entries
                            .map((e) => Text('  ${e.key}: ${e.value}'))),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

