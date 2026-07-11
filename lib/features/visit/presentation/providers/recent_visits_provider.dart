import 'package:docentral/features/visit/domain/visit_record.dart';
import 'package:docentral/features/visit/presentation/providers/visit_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recent_visits_provider.g.dart';

@riverpod
Stream<List<VisitRecord>> recentVisits(Ref ref, String patientId) {
  final Role? role = ref.watch(currentRoleProvider);
  if (role == null) return Stream.value(const <VisitRecord>[]);

  return ref
      .watch(visitRepositoryProvider)
      .watchRecentVisits(role: role, patientId: patientId);
}
