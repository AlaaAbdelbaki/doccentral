part of '../inventory_list_page.dart';

class _InventoryItemRow extends StatelessWidget {
  const _InventoryItemRow({
    required this.item,
    required this.canManageInventory,
    required this.onRestock,
    required this.onAdjustStock,
  });

  final InventoryItem item;
  final bool canManageInventory;
  final void Function(String inventoryItemId) onRestock;
  final void Function(String inventoryItemId) onAdjustStock;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
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
                  const Icon(
                    Icons.warning_amber_outlined,
                    color: Colors.orange,
                  ),
                ],
                if (canManageInventory) ...<Widget>[
                  IconButton(
                    onPressed: () => onRestock(item.id),
                    icon: const Icon(Icons.add_box_outlined),
                    tooltip: l10n.inventoryRestockButton,
                  ),
                  IconButton(
                    onPressed: () => onAdjustStock(item.id),
                    icon: const Icon(Icons.tune),
                    tooltip: l10n.inventoryAdjustStockButton,
                  ),
                ],
              ],
            ),
            Consumer(
              builder: (BuildContext context, WidgetRef ref, _) {
                final List<RestockEvent> history =
                    ref.watch(restockHistoryProvider(item.id)).value ??
                    const <RestockEvent>[];
                if (history.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    '${l10n.inventoryRestockHistorySection}: '
                    '${history.map((RestockEvent e) => '+${e.quantityAdded} '
                        '(${DateFormat('dd/MM/yyyy').format(e.restockDate)}'
                        '${e.supplier != null && e.supplier!.isNotEmpty ? ' · ${e.supplier}' : ''})').join('  ')}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            ),
            Consumer(
              builder: (BuildContext context, WidgetRef ref, _) {
                final List<StockAdjustment> history =
                    ref.watch(adjustmentHistoryProvider(item.id)).value ??
                    const <StockAdjustment>[];
                if (history.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    '${l10n.inventoryAdjustmentHistorySection}: '
                    '${history.map((StockAdjustment a) => '${a.oldQuantity}→${a.newQuantity} (${a.reason})').join('  ')}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
