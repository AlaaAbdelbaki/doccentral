part of '../inventory_list_page.dart';

class _InventoryItemRow extends StatelessWidget {
  const _InventoryItemRow({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
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
            Text('${item.onHandQuantity}'),
            const SizedBox(width: AppSpacing.md),
            Text(
              '${l10n.inventoryLowStockThresholdField}: ${item.lowStockThreshold}',
            ),
            if (item.isLowStock) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.warning_amber_outlined, color: Colors.orange),
            ],
          ],
        ),
      ),
    );
  }
}
