import 'package:docentral/features/appointment/domain/appointment_record.dart';
import 'package:docentral/features/appointment/domain/appointment_status.dart';
import 'package:docentral/features/appointment/presentation/providers/todays_appointments_provider.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/design_system/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

part 'widgets/appointment_row.dart';
part 'widgets/calendar_side_panel.dart';
part 'widgets/status_badge.dart';

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  static const double _sidePanelWidth = 280;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AsyncValue<List<AppointmentRecord>> appointmentsAsync = ref.watch(
      todaysAppointmentsProvider,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.calendarPageTitle)),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: appointmentsAsync.when(
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
            ),
          ),
          const VerticalDivider(width: 1),
          const SizedBox(width: _sidePanelWidth, child: _CalendarSidePanel()),
        ],
      ),
    );
  }
}
