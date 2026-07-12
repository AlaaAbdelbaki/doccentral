import 'package:docentral/features/clinic/domain/clinic_repository.dart';
import 'package:docentral/features/clinic/presentation/providers/clinic_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/data/providers/current_session_provider.dart';
import 'package:docentral/shared/data/providers/current_user_id_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'resolved_role_provider.g.dart';

/// The Role assigned (locally) to the currently signed-in Supabase user, or
/// null if no session is active.
///
/// Also bridges the result into [CurrentRole]/[CurrentUserId]: those are set
/// imperatively by the interactive sign-in/sign-up flows, but a session
/// restored automatically on app start (Supabase's persisted-session /
/// auto-login case) never goes through that flow, so without this bridge
/// RBAC permission checks and audit attribution would silently see a null
/// role/userId for an auto-logged-in user.
@riverpod
Future<Role?> resolvedRole(Ref ref) async {
  final Session? session = await ref.watch(currentSessionProvider.future);
  if (session == null) {
    ref.read(currentRoleProvider.notifier).clear();
    ref.read(currentUserIdProvider.notifier).clear();
    return null;
  }

  final ClinicRepository clinicRepository = ref.watch(clinicRepositoryProvider);
  final Role? role = await clinicRepository.resolveRole(session.user.id);
  if (role == null) return null;

  ref.read(currentRoleProvider.notifier).setRole(role);
  final String? userId = await clinicRepository.resolveUserId(session.user.id);
  if (userId != null) {
    ref.read(currentUserIdProvider.notifier).setUserId(userId);
  }
  return role;
}
