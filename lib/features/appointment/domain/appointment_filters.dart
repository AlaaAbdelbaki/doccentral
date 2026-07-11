import 'package:docentral/features/appointment/domain/appointment_status.dart';

class AppointmentFilters {
  const AppointmentFilters({
    this.startDate,
    this.endDate,
    this.patientNameQuery = '',
    this.status,
    this.assignedUserId,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final String patientNameQuery;
  final AppointmentStatus? status;
  final String? assignedUserId;

  bool get isActive =>
      startDate != null ||
      endDate != null ||
      patientNameQuery.trim().isNotEmpty ||
      status != null ||
      assignedUserId != null;

  AppointmentFilters copyWith({
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    String? patientNameQuery,
    AppointmentStatus? status,
    bool clearStatus = false,
    String? assignedUserId,
    bool clearAssignedUserId = false,
  }) {
    return AppointmentFilters(
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      patientNameQuery: patientNameQuery ?? this.patientNameQuery,
      status: clearStatus ? null : (status ?? this.status),
      assignedUserId: clearAssignedUserId
          ? null
          : (assignedUserId ?? this.assignedUserId),
    );
  }

  bool matches(String patientName, AppointmentStatus s, String assignedTo) {
    if (patientNameQuery.trim().isNotEmpty &&
        !patientName.toLowerCase().contains(
          patientNameQuery.trim().toLowerCase(),
        )) {
      return false;
    }
    if (status != null && status != s) return false;
    if (assignedUserId != null && assignedUserId != assignedTo) return false;
    return true;
  }
}
