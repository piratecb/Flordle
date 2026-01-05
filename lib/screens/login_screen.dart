import 'package:flutter/material.dart';
import 'package:projeto_prog_mobile_wordle/services/auth_service.dart';

/// Login screen with options for email/password, anonymous play
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _isLogin = true; // true = login, false = register
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    AuthResult result;

    if (_isLogin) {
      result = await _authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      result = await _authService.registerWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );
    }

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      setState(() => _errorMessage = result.errorMessage);
    }
  }

  Future<void> _handleResetPassword() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Introduz o email primeiro');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    AuthResult result = await _authService.resetPassword(email);

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.successMessage ?? 'Email enviado!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } else {
      setState(() => _errorMessage = result.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Entrar' : 'Criar Conta'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.games,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Flordle',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isLogin
                  ? 'Entra para guardar as tuas estatísticas'
                  : 'Cria uma conta para guardar o teu progresso',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: 32),

            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: textColor),
                      decoration: _inputDecoration(
                        label: 'Nome',
                        icon: Icons.person,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Introduz o teu nome';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: textColor),
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      label: 'Email',
                      icon: Icons.email,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Introduz o email';
                      }
                      if (!value.contains('@')) {
                        return 'Email inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    style: TextStyle(color: textColor),
                    obscureText: _obscurePassword,
                    decoration: _inputDecoration(
                      label: 'Password',
                      icon: Icons.lock,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: subtitleColor,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Introduz a password';
                      }
                      if (!_isLogin && value.length < 6) {
                        return 'Mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  if (_isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _handleResetPassword,
                        child: Text(
                          'Esqueci a password',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.onPrimary,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isLogin ? 'Entrar' : 'Criar Conta',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isLogin ? 'Não tens conta?' : 'Já tens conta?',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _errorMessage = null;
                          });
                        },
                  child: Text(
                    _isLogin ? 'Criar conta' : 'Entrar',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final fillColor = isDark ? Colors.grey[800] : Colors.grey[200];

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: labelColor),
      prefixIcon: Icon(icon, color: labelColor),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}

