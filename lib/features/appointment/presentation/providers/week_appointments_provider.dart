import 'package:docentral/features/appointment/domain/appointment_record.dart';
import 'package:docentral/features/appointment/domain/appointment_repository.dart';
import 'package:docentral/features/appointment/presentation/providers/appointment_repository_provider.dart';
import 'package:docentral/features/appointment/presentation/providers/calendar_week_anchor_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'week_appointments_provider.g.dart';

@riverpod
Stream<List<AppointmentRecord>> weekAppointments(Ref ref) {
  final Role? role = ref.watch(currentRoleProvider);
  if (role == null) return Stream.value(const <AppointmentRecord>[]);

  final DateTime weekStart = ref.watch(calendarWeekAnchorProvider);
  final AppointmentRepository repository = ref.watch(
    appointmentRepositoryProvider,
  );
  return repository.watchRange(
    role: role,
    start: weekStart,
    end: weekStart.add(const Duration(days: 7)),
  );
}
