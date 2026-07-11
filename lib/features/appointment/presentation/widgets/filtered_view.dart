part of '../calendar_page.dart';

class _FilteredView extends ConsumerWidget {
  const _FilteredView({
    required this.canManageAppointments,
    required this.canCheckIn,
    required this.patients,
    required this.assignableUsers,
  });

  final bool canManageAppointments;
  final bool canCheckIn;
  final List<PatientRecord> patients;
  final List<AssignableUser> assignableUsers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AsyncValue<List<AppointmentRecord>> appointmentsAsync = ref.watch(
      filteredAppointmentsProvider,
    );

    return appointmentsAsync.when(
      data: (List<AppointmentRecord> appointments) {
        if (appointments.isEmpty) {
          return Center(child: Text(l10n.appointmentEmptyToday));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: appointments.length,
          separatorBuilder: (BuildContext context, int index) =>
              const SizedBox(height: AppSpacing.sm),
          itemBuilder: (BuildContext context, int index) =>
              _buildAppointmentRow(
                context,
                ref,
                appointments[index],
                canManageAppointments: canManageAppointments,
                canCheckIn: canCheckIn,
                patients: patients,
                assignableUsers: assignableUsers,
              ),
        );
      },
      error: (Object error, StackTrace stackTrace) =>
          Center(child: Text('$error')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}
