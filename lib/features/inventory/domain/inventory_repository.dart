import 'package:docentral/features/inventory/domain/inventory_category.dart';
import 'package:docentral/features/inventory/domain/inventory_item.dart';
import 'package:docentral/features/inventory/domain/restock_event.dart';
import 'package:docentral/features/inventory/domain/stock_adjustment.dart';
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

  /// Records a Restock Event on [inventoryItemId], increasing its on-hand
  /// quantity by [quantityAdded]. [restockDate] defaults to today. Returns
  /// the new event's id.
  ///
  /// Throws [InventoryValidationException] if [quantityAdded] is not
  /// positive.
  Future<String> recordRestock({
    required Role role,
    required String actorUserId,
    required String inventoryItemId,
    required int quantityAdded,
    DateTime? restockDate,
    String? supplier,
    String? notes,
  });

  /// Streams the Restock Event history for [inventoryItemId], oldest first.
  Stream<List<RestockEvent>> watchRestockHistory({
    required Role role,
    required String inventoryItemId,
  });

  /// Directly sets [inventoryItemId]'s on-hand quantity to [newQuantity],
  /// logging the old quantity, new quantity, delta, actor, and [reason].
  /// Returns the new adjustment's id.
  ///
  /// Throws [InventoryValidationException] if [reason] is blank or
  /// [newQuantity] is negative.
  Future<String> adjustStock({
    required Role role,
    required String actorUserId,
    required String inventoryItemId,
    required int newQuantity,
    required String reason,
  });

  /// Streams the Stock Adjustment history for [inventoryItemId], oldest
  /// first — a distinct audit trail from Restock Events.
  Stream<List<StockAdjustment>> watchAdjustmentHistory({
    required Role role,
    required String inventoryItemId,
  });
}
