import 'package:firebase_auth/firebase_auth.dart';

/// Abstract auth interface for testability.
abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  Future<UserCredential> signInWithEmail(String email, String password);
  Future<UserCredential> signUpWithEmail(String email, String password);
  Future<UserCredential> signInWithGoogle();
  Future<void> sendPasswordReset(String email);
  Future<void> linkGoogleAccount();
  Future<void> signOut();
}