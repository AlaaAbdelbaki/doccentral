import 'package:docentral/features/inventory/domain/inventory_item.dart';
import 'package:docentral/features/inventory/presentation/providers/inventory_items_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'low_stock_items_provider.g.dart';

@riverpod
List<InventoryItem> lowStockItems(Ref ref) {
  final List<InventoryItem> items =
      ref.watch(inventoryItemsProvider).value ?? const <InventoryItem>[];
  return items.where((InventoryItem item) => item.isLowStock).toList();
}
