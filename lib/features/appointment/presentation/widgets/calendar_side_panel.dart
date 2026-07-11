part of '../calendar_page.dart';

class _CalendarSidePanel extends StatelessWidget {
  const _CalendarSidePanel();

  // No Inventory data exists yet (Epic 8) — this is a genuine zero, not a
  // stubbed placeholder value.
  static const int _lowStockCount = 0;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.calendarSidePanelTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(child: Text(l10n.calendarLowStockLabel)),
              CircleAvatar(
                radius: 12,
                child: Text(
                  '$_lowStockCount',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
