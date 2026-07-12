import 'package:docentral/features/inventory/domain/inventory_category.dart';
import 'package:docentral/features/inventory/domain/inventory_item.dart';
import 'package:docentral/features/inventory/domain/restock_event.dart';
import 'package:docentral/features/inventory/domain/stock_adjustment.dart';
import 'package:docentral/features/inventory/presentation/providers/adjustment_history_provider.dart';
import 'package:docentral/features/inventory/presentation/providers/inventory_controller_provider.dart';
import 'package:docentral/features/inventory/presentation/providers/inventory_items_provider.dart';
import 'package:docentral/features/inventory/presentation/providers/restock_history_provider.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/providers/permission_provider.dart';
import 'package:docentral/shared/design_system/app_spacing.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

part 'widgets/adjustment_form_dialog.dart';
part 'widgets/inventory_item_form_dialog.dart';
part 'widgets/inventory_item_row.dart';
part 'widgets/restock_form_dialog.dart';

class InventoryListPage extends ConsumerWidget {
  const InventoryListPage({super.key});

  static String _categoryLabel(
    AppLocalizations l10n,
    InventoryCategory category,
  ) {
    switch (category) {
      case InventoryCategory.cleaning:
        return l10n.inventoryCategoryCleaning;
      case InventoryCategory.medicament:
        return l10n.inventoryCategoryMedicament;
      case InventoryCategory.supply:
        return l10n.inventoryCategorySupply;
      case InventoryCategory.other:
        return l10n.inventoryCategoryOther;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool canManageInventory = ref.watch(permissionCheckerProvider)(
      Permission.canManageInventory,
    );
    final AsyncValue<List<InventoryItem>> itemsAsync = ref.watch(
      inventoryItemsProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navInventory),
        actions: <Widget>[
          if (canManageInventory)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: FilledButton.icon(
                onPressed: () => _showItemFormDialog(context, ref),
                icon: const Icon(Icons.add),
                label: Text(l10n.inventoryAddItemButton),
              ),
            ),
        ],
      ),
      body: itemsAsync.when(
        data: (List<InventoryItem> items) {
          if (items.isEmpty) {
            return Center(child: Text(l10n.inventoryEmptyState));
          }

          final Map<InventoryCategory, List<InventoryItem>> byCategory = {
            for (final InventoryCategory category in InventoryCategory.values)
              category: items
                  .where((InventoryItem item) => item.category == category)
                  .toList(),
          };

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              for (final InventoryCategory category in InventoryCategory.values)
                if (byCategory[category]!.isNotEmpty) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      _categoryLabel(l10n, category),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  for (final InventoryItem item in byCategory[category]!)
                    _InventoryItemRow(
                      item: item,
                      canManageInventory: canManageInventory,
                      onRestock: (String itemId) =>
                          _showRestockFormDialog(context, ref, itemId),
                      onAdjustStock: (String itemId) =>
                          _showAdjustmentFormDialog(context, ref, item),
                    ),
                  const SizedBox(height: AppSpacing.md),
                ],
            ],
          );
        },
        error: (Object error, StackTrace stackTrace) =>
            Center(child: Text('$error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _showItemFormDialog(BuildContext context, WidgetRef ref) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _InventoryItemFormDialog(
          onSubmit: (_InventoryItemFormResult result) {
            ref
                .read(inventoryControllerProvider.notifier)
                .create(
                  name: result.name,
                  category: result.category,
                  unit: result.unit,
                  onHandQuantity: result.onHandQuantity,
                  lowStockThreshold: result.lowStockThreshold,
                );
          },
        );
      },
    );
  }

  Future<void> _showRestockFormDialog(
    BuildContext context,
    WidgetRef ref,
    String inventoryItemId,
  ) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _RestockFormDialog(
          onSubmit: (_RestockFormResult result) {
            ref
                .read(inventoryControllerProvider.notifier)
                .recordRestock(
                  inventoryItemId: inventoryItemId,
                  quantityAdded: result.quantityAdded,
                  restockDate: result.restockDate,
                  supplier: result.supplier,
                  notes: result.notes,
                );
          },
        );
      },
    );
  }

  Future<void> _showAdjustmentFormDialog(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
  ) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _AdjustmentFormDialog(
          currentQuantity: item.onHandQuantity,
          onSubmit: (_AdjustmentFormResult result) {
            ref
                .read(inventoryControllerProvider.notifier)
                .adjustStock(
                  inventoryItemId: item.id,
                  newQuantity: result.newQuantity,
                  reason: result.reason,
                );
          },
        );
      },
    );
  }
}
