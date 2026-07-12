import 'package:docentral/features/day_closeout/domain/day_closeout_record.dart';
import 'package:docentral/features/day_closeout/presentation/providers/day_closeout_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'day_closeout_for_today_provider.g.dart';

@riverpod
Stream<DayCloseoutRecord?> dayCloseoutForToday(Ref ref) {
  final Role? role = ref.watch(currentRoleProvider);
  if (role == null) return Stream.value(null);

  return ref
      .watch(dayCloseoutRepositoryProvider)
      .watchCloseoutForDay(role: role, day: DateTime.now());
}
