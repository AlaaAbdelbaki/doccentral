import 'package:docentral/shared/data/auth/supabase_auth_service.dart';
import 'package:docentral/shared/data/providers/supabase_client_provider.dart';
import 'package:docentral/shared/domain/auth/auth_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_service_provider.g.dart';

@riverpod
AuthService authService(Ref ref) =>
    SupabaseAuthService(ref.watch(supabaseClientProvider));
