part of '../calendar_page.dart';

class _CalendarSidePanel extends ConsumerWidget {
  const _CalendarSidePanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final int lowStockCount = ref.watch(lowStockCountProvider);

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
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const LowStockPage(),
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(child: Text(l10n.calendarLowStockLabel)),
                CircleAvatar(
                  radius: 12,
                  child: Text(
                    '$lowStockCount',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
