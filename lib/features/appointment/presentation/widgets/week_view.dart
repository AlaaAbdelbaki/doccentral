part of '../calendar_page.dart';

class _WeekView extends ConsumerWidget {
  const _WeekView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String localeName = Localizations.localeOf(context).toString();
    final DateTime weekStart = ref.watch(calendarWeekAnchorProvider);
    final DateTime weekEnd = weekStart.add(const Duration(days: 6));
    final AsyncValue<List<AppointmentRecord>> appointmentsAsync = ref.watch(
      weekAppointmentsProvider,
    );

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                onPressed: () =>
                    ref.read(calendarWeekAnchorProvider.notifier).previous(),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${DateFormat('d MMM', localeName).format(weekStart)} '
                '– ${DateFormat('d MMM', localeName).format(weekEnd)}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              IconButton(
                onPressed: () =>
                    ref.read(calendarWeekAnchorProvider.notifier).next(),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: appointmentsAsync.when(
            data: (List<AppointmentRecord> appointments) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (int i = 0; i < 7; i++)
                    Expanded(
                      child: _WeekDayColumn(
                        date: weekStart.add(Duration(days: i)),
                        localeName: localeName,
                        appointments: appointments
                            .where(
                              (AppointmentRecord a) => _isSameDay(
                                a.startTime,
                                weekStart.add(Duration(days: i)),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              );
            },
            error: (Object error, StackTrace stackTrace) =>
                Center(child: Text('$error')),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _WeekDayColumn extends StatelessWidget {
  const _WeekDayColumn({
    required this.date,
    required this.localeName,
    required this.appointments,
  });

  final DateTime date;
  final String localeName;
  final List<AppointmentRecord> appointments;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(
              DateFormat('EEE d', localeName).format(date),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Expanded(
            child: appointments.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Text(
                      l10n.appointmentEmptyDayShort,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    itemCount: appointments.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (BuildContext context, int index) =>
                        _WeekAppointmentTile(appointment: appointments[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _WeekAppointmentTile extends StatelessWidget {
  const _WeekAppointmentTile({required this.appointment});

  final AppointmentRecord appointment;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              DateFormat('HH:mm').format(appointment.startTime),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Text(
              appointment.patientName,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            _StatusBadge(status: appointment.status),
          ],
        ),
      ),
    );
  }
}
