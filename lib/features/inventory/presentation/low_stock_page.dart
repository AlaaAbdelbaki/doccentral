import 'package:docentral/features/inventory/domain/inventory_item.dart';
import 'package:docentral/features/inventory/presentation/providers/low_stock_items_provider.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/design_system/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LowStockPage extends ConsumerWidget {
  const LowStockPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final List<InventoryItem> items = ref.watch(lowStockItemsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.calendarLowStockLabel)),
      body: items.isEmpty
          ? Center(child: Text(l10n.lowStockEmptyState))
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: items.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (BuildContext context, int index) {
                final InventoryItem item = items[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        Text(item.unit),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          '${item.onHandQuantity} / '
                          '${l10n.inventoryLowStockThresholdField}: '
                          '${item.lowStockThreshold}',
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(
                          Icons.warning_amber_outlined,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
