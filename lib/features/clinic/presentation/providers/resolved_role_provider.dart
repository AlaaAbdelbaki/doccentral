import 'package:docentral/features/clinic/presentation/providers/clinic_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_session_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'resolved_role_provider.g.dart';

/// The Role assigned (locally) to the currently signed-in Supabase user,
/// or null if no session is active.
@riverpod
Future<Role?> resolvedRole(Ref ref) async {
  final Session? session = await ref.watch(currentSessionProvider.future);
  if (session == null) return null;
  return ref.watch(clinicRepositoryProvider).resolveRole(session.user.id);
}
