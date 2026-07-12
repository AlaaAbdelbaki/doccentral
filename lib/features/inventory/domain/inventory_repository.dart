import 'package:docentral/features/inventory/domain/inventory_category.dart';
import 'package:docentral/features/inventory/domain/inventory_item.dart';
import 'package:docentral/shared/domain/rbac/role.dart';

abstract class InventoryRepository {
  /// Streams all Inventory Items, oldest first.
  Stream<List<InventoryItem>> watchAll({required Role role});

  /// Creates an Inventory Item. Returns the new item's id.
  ///
  /// Throws [InventoryValidationException] if [onHandQuantity] or
  /// [lowStockThreshold] is negative.
  Future<String> create({
    required Role role,
    required String name,
    required InventoryCategory category,
    required String unit,
    required int onHandQuantity,
    required int lowStockThreshold,
  });
}
