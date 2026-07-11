import 'package:docentral/features/appointment/domain/appointment_filters.dart';
import 'package:docentral/features/appointment/domain/appointment_status.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'appointment_filters_provider.g.dart';

@riverpod
class AppointmentFiltersController extends _$AppointmentFiltersController {
  @override
  AppointmentFilters build() => const AppointmentFilters();

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(
      startDate: start,
      clearStartDate: start == null,
      endDate: end,
      clearEndDate: end == null,
    );
  }

  void setPatientNameQuery(String query) {
    state = state.copyWith(patientNameQuery: query);
  }

  void setStatus(AppointmentStatus? status) {
    state = state.copyWith(status: status, clearStatus: status == null);
  }

  void setAssignedUserId(String? assignedUserId) {
    state = state.copyWith(
      assignedUserId: assignedUserId,
      clearAssignedUserId: assignedUserId == null,
    );
  }

  void clearAll() => state = const AppointmentFilters();
}
