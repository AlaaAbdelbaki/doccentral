import 'package:docentral/shared/domain/auth/auth_exceptions.dart';

abstract class AuthService {
  /// Returns the new user's remote auth id on success.
  /// Throws [AuthException] on failure (offline, invalid credentials, etc).
  Future<String> signUp({required String email, required String password});

  /// Returns the signed-in user's remote auth id on success.
  /// Throws [AuthException] on failure (offline, invalid credentials, etc).
  Future<String> signIn({required String email, required String password});

  Future<void> signOut();
}
