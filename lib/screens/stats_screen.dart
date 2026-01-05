import 'package:flutter/material.dart';
import 'package:projeto_prog_mobile_wordle/services/auth_service.dart';
import 'package:projeto_prog_mobile_wordle/screens/login_screen.dart';

/// Statistics screen showing player stats and profile options
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    final stats = await _authService.getUserStats();

    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _openLogin() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );

    if (result == true) {
      _loadStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final isLoggedIn = user != null && !user.isAnonymous;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estatísticas'),
        actions: [
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sair',
              onPressed: _handleLogout,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileSection(isLoggedIn, user),
                  const SizedBox(height: 32),

                  if (_stats != null || !isLoggedIn)
                    _buildStatsSection(),

                  const SizedBox(height: 24),

                  if (_stats != null)
                    _buildGuessDistribution(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileSection(bool isLoggedIn, dynamic user) {
    final cardColor = Theme.of(context).cardTheme.color;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: isLoggedIn
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[600],
            child: Icon(
              isLoggedIn ? Icons.person : Icons.person_outline,
              size: 40,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isLoggedIn
                ? (user?.displayName ?? 'Jogador')
                : 'Convidado',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (isLoggedIn && user?.email != null) ...[
            const SizedBox(height: 4),
            Text(
              user!.email!,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
            ),
          ],
          if (!isLoggedIn) ...[
            const SizedBox(height: 8),
            Text(
              'Cria uma conta para guardar as tuas estatísticas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openLogin,
              icon: const Icon(Icons.login),
              label: const Text('Entrar / Criar Conta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final gamesPlayed = _stats?['gamesPlayed'] ?? 0;
    final gamesWon = _stats?['gamesWon'] ?? 0;
    final currentStreak = _stats?['currentStreak'] ?? 0;
    final maxStreak = _stats?['maxStreak'] ?? 0;
    final averageAttempts = (_stats?['averageAttempts'] as num?)?.toDouble() ?? 0.0;
    final winRate = gamesPlayed > 0
        ? (gamesWon / gamesPlayed * 100).round()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RESUMO',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(gamesPlayed.toString(), 'Jogos'),
            _buildStatItem('$winRate%', 'Vitórias'),
            _buildStatItem(currentStreak.toString(), 'Streak\nAtual'),
            _buildStatItem(maxStreak.toString(), 'Melhor\nStreak'),
          ],
        ),
        const SizedBox(height: 16),
        if (gamesWon > 0)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Média: ${averageAttempts.toStringAsFixed(1)} tentativas',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtitleColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[400]
        : Colors.grey[600];

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: subtitleColor,
          ),
        ),
      ],
    );
  }

  Widget _buildGuessDistribution() {
    final distribution = _stats?['guessDistribution'] as Map<String, dynamic>? ?? {};
    final maxValue = distribution.values
        .map((v) => v as int)
        .fold(1, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DISTRIBUIÇÃO DE TENTATIVAS',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(6, (index) {
          final attempt = (index + 1).toString();
          final count = distribution[attempt] ?? 0;
          final percentage = maxValue > 0 ? count / maxValue : 0.0;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final textColor = Theme.of(context).colorScheme.onSurface;
          final barBgColor = isDark ? Colors.grey[700] : Colors.grey[300];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Text(
                    attempt,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: barBgColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: percentage > 0 ? percentage : 0.05,
                        child: Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            count.toString(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

