import 'package:docentral/features/appointment/domain/appointment_exceptions.dart';
import 'package:docentral/features/appointment/domain/appointment_filters.dart';
import 'package:docentral/features/appointment/domain/appointment_record.dart';
import 'package:docentral/features/appointment/domain/appointment_status.dart';
import 'package:docentral/features/appointment/domain/assignable_user.dart';
import 'package:docentral/features/appointment/domain/cancellation_reason.dart';
import 'package:docentral/features/appointment/presentation/providers/appointment_controller_provider.dart';
import 'package:docentral/features/appointment/presentation/providers/appointment_filters_provider.dart';
import 'package:docentral/features/appointment/presentation/providers/appointment_patient_options_provider.dart';
import 'package:docentral/features/appointment/presentation/providers/assignable_users_provider.dart';
import 'package:docentral/features/appointment/presentation/providers/calendar_view_mode_provider.dart';
import 'package:docentral/features/appointment/presentation/providers/calendar_week_anchor_provider.dart';
import 'package:docentral/features/appointment/presentation/providers/filtered_appointments_provider.dart';
import 'package:docentral/features/appointment/presentation/providers/todays_appointments_provider.dart';
import 'package:docentral/features/appointment/presentation/providers/week_appointments_provider.dart';
import 'package:docentral/features/patient/domain/patient_record.dart';
import 'package:docentral/features/patient/presentation/providers/selected_patient_provider.dart';
import 'package:docentral/features/visit/domain/visit_exceptions.dart';
import 'package:docentral/features/visit/domain/visit_record.dart';
import 'package:docentral/features/visit/domain/visit_status.dart';
import 'package:docentral/features/visit/presentation/providers/visit_controller_provider.dart';
import 'package:docentral/features/visit/presentation/providers/visit_for_appointment_provider.dart';
import 'package:docentral/features/visit/presentation/visit_detail_page.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/providers/permission_provider.dart';
import 'package:docentral/shared/data/router/app_routes.dart';
import 'package:docentral/shared/design_system/app_spacing.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

part 'widgets/appointment_form_dialog.dart';
part 'widgets/appointment_row.dart';
part 'widgets/calendar_side_panel.dart';
part 'widgets/cancel_reason_dialog.dart';
part 'widgets/day_view.dart';
part 'widgets/filter_bar.dart';
part 'widgets/filtered_view.dart';
part 'widgets/status_badge.dart';
part 'widgets/week_view.dart';

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  static const double _sidePanelWidth = 280;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final CalendarViewMode viewMode = ref.watch(
      calendarViewModeControllerProvider,
    );
    final bool canManageAppointments = ref.watch(permissionCheckerProvider)(
      Permission.canManageAppointments,
    );
    final bool canCheckIn = ref.watch(permissionCheckerProvider)(
      Permission.canCheckInPatient,
    );
    final List<PatientRecord> patients =
        ref.watch(appointmentPatientOptionsProvider).value ??
        const <PatientRecord>[];
    final List<AssignableUser> assignableUsers =
        ref.watch(assignableUsersProvider).value ?? const <AssignableUser>[];
    final AppointmentFilters filters = ref.watch(
      appointmentFiltersControllerProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.calendarPageTitle),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SegmentedButton<CalendarViewMode>(
              segments: <ButtonSegment<CalendarViewMode>>[
                ButtonSegment<CalendarViewMode>(
                  value: CalendarViewMode.day,
                  label: Text(l10n.calendarViewDay),
                ),
                ButtonSegment<CalendarViewMode>(
                  value: CalendarViewMode.week,
                  label: Text(l10n.calendarViewWeek),
                ),
              ],
              selected: <CalendarViewMode>{viewMode},
              onSelectionChanged: (Set<CalendarViewMode> selection) {
                ref
                    .read(calendarViewModeControllerProvider.notifier)
                    .setMode(selection.first);
              },
            ),
          ),
          if (canManageAppointments)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: FilledButton.icon(
                onPressed: () => _showAppointmentFormDialog(
                  context,
                  ref,
                  patients: patients,
                  assignableUsers: assignableUsers,
                ),
                icon: const Icon(Icons.add),
                label: Text(l10n.appointmentAddButton),
              ),
            ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _FilterBar(assignableUsers: assignableUsers),
          const Divider(height: 1),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: filters.isActive
                      ? _FilteredView(
                          canManageAppointments: canManageAppointments,
                          canCheckIn: canCheckIn,
                          patients: patients,
                          assignableUsers: assignableUsers,
                        )
                      : switch (viewMode) {
                          CalendarViewMode.day => _DayView(
                            canManageAppointments: canManageAppointments,
                            canCheckIn: canCheckIn,
                            patients: patients,
                            assignableUsers: assignableUsers,
                          ),
                          CalendarViewMode.week => const _WeekView(),
                        },
                ),
                const VerticalDivider(width: 1),
                const SizedBox(
                  width: _sidePanelWidth,
                  child: _CalendarSidePanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showAppointmentFormDialog(
  BuildContext context,
  WidgetRef ref, {
  required List<PatientRecord> patients,
  required List<AssignableUser> assignableUsers,
  AppointmentRecord? initial,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return _AppointmentFormDialog(
        initial: initial,
        patients: patients,
        assignableUsers: assignableUsers,
        onSubmit: (AppointmentFormResult result) {
          _handleSubmit(context, ref, initial: initial, result: result);
        },
      );
    },
  );
}

Future<void> _handleSubmit(
  BuildContext context,
  WidgetRef ref, {
  required AppointmentRecord? initial,
  required AppointmentFormResult result,
}) async {
  final AppointmentController controller = ref.read(
    appointmentControllerProvider.notifier,
  );

  if (initial == null) {
    await controller.create(
      patientId: result.patientId,
      assignedUserId: result.assignedUserId,
      startTime: result.startTime,
      endTime: result.endTime,
      reason: result.reason,
      notes: result.notes,
    );
  } else {
    await controller.updateAppointment(
      appointmentId: initial.id,
      assignedUserId: result.assignedUserId,
      startTime: result.startTime,
      endTime: result.endTime,
      reason: result.reason,
      notes: result.notes,
    );
  }

  final Object? error = ref.read(appointmentControllerProvider).error;
  if (error is AppointmentOverlapException) {
    if (!context.mounted) return;
    final bool confirmed = await _confirmOverlap(context);
    if (!confirmed) return;

    if (initial == null) {
      await controller.create(
        patientId: result.patientId,
        assignedUserId: result.assignedUserId,
        startTime: result.startTime,
        endTime: result.endTime,
        reason: result.reason,
        notes: result.notes,
        overrideOverlap: true,
      );
    } else {
      await controller.updateAppointment(
        appointmentId: initial.id,
        assignedUserId: result.assignedUserId,
        startTime: result.startTime,
        endTime: result.endTime,
        reason: result.reason,
        notes: result.notes,
        overrideOverlap: true,
      );
    }
  } else if (error is AppointmentNotEditableException) {
    if (!context.mounted) return;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.appointmentNotEditableError)));
  }
}

Future<void> _cancelAppointmentFlow(
  BuildContext context,
  WidgetRef ref,
  AppointmentRecord appointment, {
  required List<PatientRecord> patients,
  required List<AssignableUser> assignableUsers,
}) async {
  final CancellationReason? reason = await showDialog<CancellationReason>(
    context: context,
    builder: (BuildContext dialogContext) => const _CancelReasonDialog(),
  );
  if (reason == null) return;

  if (reason == CancellationReason.rescheduled) {
    if (!context.mounted) return;
    await _showRescheduleDialog(
      context,
      ref,
      original: appointment,
      patients: patients,
      assignableUsers: assignableUsers,
    );
    return;
  }

  await ref
      .read(appointmentControllerProvider.notifier)
      .cancel(appointmentId: appointment.id, reason: reason);

  final Object? error = ref.read(appointmentControllerProvider).error;
  if (error is AppointmentNotEditableException) {
    if (!context.mounted) return;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.appointmentNotEditableError)));
  }
}

Future<void> _showRescheduleDialog(
  BuildContext context,
  WidgetRef ref, {
  required AppointmentRecord original,
  required List<PatientRecord> patients,
  required List<AssignableUser> assignableUsers,
}) {
  final AppLocalizations l10n = AppLocalizations.of(context)!;
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return _AppointmentFormDialog(
        title: l10n.appointmentRescheduleFormTitle,
        patients: patients,
        assignableUsers: assignableUsers,
        prefillPatientId: original.patientId,
        prefillAssignedUserId: original.assignedUserId,
        onSubmit: (AppointmentFormResult result) {
          _handleReschedule(context, ref, original: original, result: result);
        },
      );
    },
  );
}

Future<void> _handleReschedule(
  BuildContext context,
  WidgetRef ref, {
  required AppointmentRecord original,
  required AppointmentFormResult result,
}) async {
  final AppointmentController controller = ref.read(
    appointmentControllerProvider.notifier,
  );

  await controller.reschedule(
    appointmentId: original.id,
    newAssignedUserId: result.assignedUserId,
    newStartTime: result.startTime,
    newEndTime: result.endTime,
    newReason: result.reason,
    newNotes: result.notes,
  );

  final Object? error = ref.read(appointmentControllerProvider).error;
  if (error is AppointmentOverlapException) {
    if (!context.mounted) return;
    final bool confirmed = await _confirmOverlap(context);
    if (!confirmed) return;

    await controller.reschedule(
      appointmentId: original.id,
      newAssignedUserId: result.assignedUserId,
      newStartTime: result.startTime,
      newEndTime: result.endTime,
      newReason: result.reason,
      newNotes: result.notes,
      overrideOverlap: true,
    );
  } else if (error is AppointmentNotEditableException) {
    if (!context.mounted) return;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.appointmentNotEditableError)));
  }
}

Future<void> _checkInAppointment(
  BuildContext context,
  WidgetRef ref,
  AppointmentRecord appointment,
) async {
  await ref
      .read(visitControllerProvider.notifier)
      .checkIn(appointmentId: appointment.id);

  final Object? error = ref.read(visitControllerProvider).error;
  if (error is AppointmentNotEditableException) {
    if (!context.mounted) return;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.appointmentNotEditableError)));
  }
}

Widget _buildAppointmentRow(
  BuildContext context,
  WidgetRef ref,
  AppointmentRecord appointment, {
  required bool canManageAppointments,
  required bool canCheckIn,
  required List<PatientRecord> patients,
  required List<AssignableUser> assignableUsers,
}) {
  final bool canEdit =
      canManageAppointments &&
      appointment.status == AppointmentStatus.scheduled;

  VisitRecord? visit;
  if (appointment.status == AppointmentStatus.checkedIn) {
    visit = ref.watch(visitForAppointmentProvider(appointment.id)).value;
  }
  final bool canEditVisit = ref.watch(permissionCheckerProvider)(
    Permission.canEditVisit,
  );

  return _AppointmentRow(
    appointment: appointment,
    onEdit: !canEdit
        ? null
        : () => _showAppointmentFormDialog(
            context,
            ref,
            patients: patients,
            assignableUsers: assignableUsers,
            initial: appointment,
          ),
    onCancel: !canEdit
        ? null
        : () => _cancelAppointmentFlow(
            context,
            ref,
            appointment,
            patients: patients,
            assignableUsers: assignableUsers,
          ),
    onCheckIn: !canCheckIn || appointment.status != AppointmentStatus.scheduled
        ? null
        : () => _checkInAppointment(context, ref, appointment),
    onViewPatientFile:
        appointment.status != AppointmentStatus.checkedIn &&
            appointment.status != AppointmentStatus.completed
        ? null
        : () => _viewPatientFile(context, ref, appointment, patients),
    visitStatus: visit?.status,
    onStartVisit: !canEditVisit || visit?.status != VisitStatus.checkedIn
        ? null
        : () => _startVisitProgress(context, ref, appointment),
    onViewVisit: visit == null ? null : () => _viewVisit(context, appointment),
  );
}

void _viewVisit(BuildContext context, AppointmentRecord appointment) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (BuildContext context) => VisitDetailPage(
        appointmentId: appointment.id,
        patientName: appointment.patientName,
      ),
    ),
  );
}

Future<void> _startVisitProgress(
  BuildContext context,
  WidgetRef ref,
  AppointmentRecord appointment,
) async {
  await ref
      .read(visitControllerProvider.notifier)
      .startProgress(appointmentId: appointment.id);

  final Object? error = ref.read(visitControllerProvider).error;
  if (error is VisitNotEditableException) {
    if (!context.mounted) return;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.visitNotEditableError)));
  }
}

void _viewPatientFile(
  BuildContext context,
  WidgetRef ref,
  AppointmentRecord appointment,
  List<PatientRecord> patients,
) {
  PatientRecord? patient;
  for (final PatientRecord candidate in patients) {
    if (candidate.id == appointment.patientId) {
      patient = candidate;
      break;
    }
  }
  if (patient == null) return;

  ref.read(selectedPatientProvider.notifier).select(patient);
  context.goNamed(AppRoutes.patients.name);
}

Future<bool> _confirmOverlap(BuildContext context) async {
  final AppLocalizations l10n = AppLocalizations.of(context)!;
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(l10n.appointmentOverlapConfirmTitle),
        content: Text(l10n.appointmentOverlapConfirmMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
