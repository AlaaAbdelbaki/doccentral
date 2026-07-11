import 'package:docentral/shared/domain/auth/auth_exceptions.dart' as domain;
import 'package:docentral/shared/domain/auth/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService implements AuthService {
  const SupabaseAuthService(this._client);

  final SupabaseClient _client;

  @override
  Future<String> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      final String? userId = response.user?.id;
      if (userId == null) {
        throw const domain.AuthException('Sign-up did not return a user id');
      }
      return userId;
    } catch (error) {
      throw domain.AuthException(error.toString());
    }
  }

  @override
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final String? userId = response.user?.id;
      if (userId == null) {
        throw const domain.AuthException('Sign-in did not return a user id');
      }
      return userId;
    } catch (error) {
      throw domain.AuthException(error.toString());
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}
