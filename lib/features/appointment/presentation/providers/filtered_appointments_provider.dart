import 'package:docentral/features/appointment/domain/appointment_filters.dart';
import 'package:docentral/features/appointment/domain/appointment_record.dart';
import 'package:docentral/features/appointment/presentation/providers/appointment_filters_provider.dart';
import 'package:docentral/features/appointment/presentation/providers/appointment_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'filtered_appointments_provider.g.dart';

/// Appointments matching the active [AppointmentFiltersController], scoped to
/// the filter's date range if set, otherwise to today.
@riverpod
Stream<List<AppointmentRecord>> filteredAppointments(Ref ref) {
  final Role? role = ref.watch(currentRoleProvider);
  if (role == null) return Stream.value(const <AppointmentRecord>[]);

  final AppointmentFilters filters = ref.watch(
    appointmentFiltersControllerProvider,
  );

  final DateTime now = DateTime.now();
  final DateTime start =
      filters.startDate ?? DateTime(now.year, now.month, now.day);
  final DateTime end = (filters.endDate ?? start).add(const Duration(days: 1));

  return ref
      .watch(appointmentRepositoryProvider)
      .watchRange(role: role, start: start, end: end)
      .map(
        (List<AppointmentRecord> appointments) => appointments
            .where(
              (AppointmentRecord a) =>
                  filters.matches(a.patientName, a.status, a.assignedUserId),
            )
            .toList(),
      );
}
