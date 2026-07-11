import 'package:docentral/features/appointment/domain/cancellation_reason.dart';
import 'package:docentral/features/appointment/presentation/providers/appointment_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/data/providers/current_user_id_provider.dart';
import 'package:docentral/shared/domain/exceptions/permission_denied_exception.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'appointment_controller_provider.g.dart';

@Riverpod(keepAlive: true)
class AppointmentController extends _$AppointmentController {
  @override
  FutureOr<void> build() {}

  Future<void> create({
    required String patientId,
    required String assignedUserId,
    required DateTime startTime,
    required DateTime endTime,
    String? reason,
    String? notes,
    bool overrideOverlap = false,
  }) async {
    final Role? role = ref.read(currentRoleProvider);
    if (role == null) {
      state = AsyncError(
        const PermissionDeniedException(Permission.canManageAppointments),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(appointmentRepositoryProvider)
          .createAppointment(
            role: role,
            patientId: patientId,
            assignedUserId: assignedUserId,
            startTime: startTime,
            endTime: endTime,
            reason: reason,
            notes: notes,
            overrideOverlap: overrideOverlap,
          ),
    );
  }

  Future<void> updateAppointment({
    required String appointmentId,
    required String assignedUserId,
    required DateTime startTime,
    required DateTime endTime,
    String? reason,
    String? notes,
    bool overrideOverlap = false,
  }) async {
    final Role? role = ref.read(currentRoleProvider);
    final String? actorUserId = ref.read(currentUserIdProvider);
    if (role == null || actorUserId == null) {
      state = AsyncError(
        const PermissionDeniedException(Permission.canManageAppointments),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(appointmentRepositoryProvider)
          .updateAppointment(
            role: role,
            actorUserId: actorUserId,
            appointmentId: appointmentId,
            assignedUserId: assignedUserId,
            startTime: startTime,
            endTime: endTime,
            reason: reason,
            notes: notes,
            overrideOverlap: overrideOverlap,
          ),
    );
  }

  Future<void> cancel({
    required String appointmentId,
    required CancellationReason reason,
  }) async {
    final Role? role = ref.read(currentRoleProvider);
    final String? actorUserId = ref.read(currentUserIdProvider);
    if (role == null || actorUserId == null) {
      state = AsyncError(
        const PermissionDeniedException(Permission.canManageAppointments),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(appointmentRepositoryProvider)
          .cancelAppointment(
            role: role,
            actorUserId: actorUserId,
            appointmentId: appointmentId,
            reason: reason,
          ),
    );
  }

  Future<void> reschedule({
    required String appointmentId,
    required String newAssignedUserId,
    required DateTime newStartTime,
    required DateTime newEndTime,
    String? newReason,
    String? newNotes,
    bool overrideOverlap = false,
  }) async {
    final Role? role = ref.read(currentRoleProvider);
    final String? actorUserId = ref.read(currentUserIdProvider);
    if (role == null || actorUserId == null) {
      state = AsyncError(
        const PermissionDeniedException(Permission.canManageAppointments),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(appointmentRepositoryProvider)
          .rescheduleAppointment(
            role: role,
            actorUserId: actorUserId,
            appointmentId: appointmentId,
            newAssignedUserId: newAssignedUserId,
            newStartTime: newStartTime,
            newEndTime: newEndTime,
            newReason: newReason,
            newNotes: newNotes,
            overrideOverlap: overrideOverlap,
          ),
    );
  }
}
