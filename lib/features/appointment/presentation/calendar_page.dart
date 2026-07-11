import 'package:docentral/features/appointment/domain/appointment_record.dart';
import 'package:docentral/features/appointment/domain/appointment_status.dart';
import 'package:docentral/features/appointment/presentation/providers/calendar_view_mode_provider.dart';
import 'package:docentral/features/appointment/presentation/providers/calendar_week_anchor_provider.dart';
import 'package:docentral/features/appointment/presentation/providers/todays_appointments_provider.dart';
import 'package:docentral/features/appointment/presentation/providers/week_appointments_provider.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/design_system/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

part 'widgets/appointment_row.dart';
part 'widgets/calendar_side_panel.dart';
part 'widgets/day_view.dart';
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
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: switch (viewMode) {
              CalendarViewMode.day => const _DayView(),
              CalendarViewMode.week => const _WeekView(),
            },
          ),
          const VerticalDivider(width: 1),
          const SizedBox(width: _sidePanelWidth, child: _CalendarSidePanel()),
        ],
      ),
    );
  }
}
