import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service class to handle Firebase Authentication
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register with email and password
  Future<AuthResult> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // Update display name
        await user.updateDisplayName(displayName);

        // Create user document in Firestore
        await _createUserDocument(user.uid, displayName, email);

        return AuthResult.success(user);
      }

      return AuthResult.failure('Erro ao criar utilizador');
    } on FirebaseException catch (e) {
      return AuthResult.failure(_getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('Erro inesperado: $e');
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return AuthResult.success(result.user);
    } on FirebaseException catch (e) {
      return AuthResult.failure(_getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('Erro inesperado: $e');
    }
  }

  /// Sign in anonymously (play without account)
  Future<AuthResult> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      return AuthResult.success(result.user);
    } on FirebaseException catch (e) {
      return AuthResult.failure(_getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('Erro inesperado: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Reset password
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.success(null, message: 'Email de recuperação enviado!');
    } on FirebaseException catch (e) {
      return AuthResult.failure(_getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('Erro inesperado: $e');
    }
  }

  /// Convert anonymous account to permanent account
  Future<AuthResult> linkAnonymousAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      User? user = currentUser;
      if (user == null || !user.isAnonymous) {
        return AuthResult.failure('Utilizador não é anónimo');
      }

      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      UserCredential result = await user.linkWithCredential(credential);

      if (result.user != null) {
        await result.user!.updateDisplayName(displayName);
        await _createUserDocument(result.user!.uid, displayName, email);
        return AuthResult.success(result.user);
      }

      return AuthResult.failure('Erro ao converter conta');
    } on FirebaseException catch (e) {
      return AuthResult.failure(_getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('Erro inesperado: $e');
    }
  }

  /// Create user document in Firestore
  Future<void> _createUserDocument(String uid, String displayName, String email) async {
    await _firestore.collection('users').doc(uid).set({
      'displayName': displayName,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'gamesPlayed': 0,
      'gamesWon': 0,
      'currentStreak': 0,
      'maxStreak': 0,
      'guessDistribution': {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0, '6': 0},
      'totalAttempts': 0,
      'averageAttempts': 0.0,
    }, SetOptions(merge: true));
  }

  /// Get user stats from Firestore
  Future<Map<String, dynamic>?> getUserStats() async {
    if (currentUser == null) return null;

    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('❌ Erro ao buscar estatísticas: $e');
      return null;
    }
  }

  /// Update user stats after a game
  Future<void> updateUserStats({
    required bool won,
    required int attempts,
  }) async {
    if (currentUser == null) return;

    try {
      DocumentReference userRef = _firestore.collection('users').doc(currentUser!.uid);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userRef);

        Map<String, dynamic> data = {};
        if (snapshot.exists) {
          data = snapshot.data() as Map<String, dynamic>;
        }

        int gamesPlayed = (data['gamesPlayed'] ?? 0) + 1;
        int gamesWon = (data['gamesWon'] ?? 0) + (won ? 1 : 0);
        int currentStreak = won ? (data['currentStreak'] ?? 0) + 1 : 0;
        int maxStreak = data['maxStreak'] ?? 0;

        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }

        Map<String, dynamic> distribution = Map<String, dynamic>.from(
          data['guessDistribution'] ?? {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0, '6': 0}
        );

        if (won && attempts >= 1 && attempts <= 6) {
          distribution[attempts.toString()] = (distribution[attempts.toString()] ?? 0) + 1;
        }

        // Calculate total and average attempts (only for won games)
        int totalAttempts = (data['totalAttempts'] ?? 0) + (won ? attempts : 0);
        double averageAttempts = gamesWon > 0 ? totalAttempts / gamesWon : 0.0;

        transaction.set(userRef, {
          'gamesPlayed': gamesPlayed,
          'gamesWon': gamesWon,
          'currentStreak': currentStreak,
          'maxStreak': maxStreak,
          'guessDistribution': distribution,
          'lastPlayed': FieldValue.serverTimestamp(),
          'totalAttempts': totalAttempts,
          'averageAttempts': averageAttempts,
        }, SetOptions(merge: true));
      });

      print('✅ Estatísticas atualizadas');
    } catch (e) {
      print('❌ Erro ao atualizar estatísticas: $e');
    }
  }

  /// Get error message in Portuguese
  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este email já está registado';
      case 'invalid-email':
        return 'Email inválido';
      case 'weak-password':
        return 'Password demasiado fraca (mínimo 6 caracteres)';
      case 'user-not-found':
        return 'Utilizador não encontrado';
      case 'wrong-password':
        return 'Password incorreta';
      case 'user-disabled':
        return 'Conta desativada';
      case 'too-many-requests':
        return 'Demasiadas tentativas. Tente mais tarde';
      case 'operation-not-allowed':
        return 'Operação não permitida';
      case 'invalid-credential':
        return 'Email ou password incorretos';
      case 'configuration-not-found':
        return 'Autenticação não configurada. Ative Email/Password no Firebase Console.';
      case 'network-request-failed':
        return 'Erro de conexão. Verifique a sua internet.';
      default:
        return 'Erro de autenticação: $code';
    }
  }
}

/// Result class for authentication operations
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? errorMessage;
  final String? successMessage;

  AuthResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
    this.successMessage,
  });

  factory AuthResult.success(User? user, {String? message}) {
    return AuthResult._(
      isSuccess: true,
      user: user,
      successMessage: message,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

