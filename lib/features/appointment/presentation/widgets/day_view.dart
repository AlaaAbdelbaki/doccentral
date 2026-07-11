part of '../calendar_page.dart';

class _DayView extends ConsumerWidget {
  const _DayView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AsyncValue<List<AppointmentRecord>> appointmentsAsync = ref.watch(
      todaysAppointmentsProvider,
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
              _AppointmentRow(appointment: appointments[index]),
        );
      },
      error: (Object error, StackTrace stackTrace) =>
          Center(child: Text('$error')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}
