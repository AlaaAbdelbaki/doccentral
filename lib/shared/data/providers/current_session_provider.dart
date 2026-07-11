import 'package:docentral/shared/data/providers/supabase_client_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'current_session_provider.g.dart';

@riverpod
Stream<Session?> currentSession(Ref ref) {
  final SupabaseClient client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange.map((AuthState state) => state.session);
}
