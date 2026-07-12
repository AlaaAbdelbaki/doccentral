import 'package:docentral/features/inventory/domain/inventory_category.dart';
import 'package:docentral/features/inventory/domain/inventory_exceptions.dart';
import 'package:docentral/features/inventory/domain/inventory_item.dart';
import 'package:docentral/features/inventory/domain/inventory_repository.dart';
import 'package:docentral/features/inventory/domain/restock_event.dart';
import 'package:docentral/features/inventory/domain/stock_adjustment.dart';
import 'package:docentral/shared/data/database/app_database.dart';
import 'package:docentral/shared/data/database/tables/inventory_items_table.dart';
import 'package:docentral/shared/data/database/tables/restock_events_table.dart';
import 'package:docentral/shared/data/database/tables/stock_adjustments_table.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/permission_guard.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  InventoryRepositoryImpl(this._db, {Uuid uuid = const Uuid()}) : _uuid = uuid;

  final AppDatabase _db;
  final Uuid _uuid;

  @override
  Stream<List<InventoryItem>> watchAll({required Role role}) {
    requirePermission(role, Permission.canViewInventory);

    final SimpleSelectStatement<$InventoryItemsTable, InventoryItemRow> select =
        _db.select(_db.inventoryItems)
          ..where((InventoryItems t) => t.deletedAt.isNull())
          ..orderBy([(InventoryItems t) => OrderingTerm.asc(t.createdAt)]);

    return select.watch().map(
      (List<InventoryItemRow> rows) =>
          rows.map(_toDomain).toList(growable: false),
    );
  }

  InventoryItem _toDomain(InventoryItemRow row) {
    return InventoryItem(
      id: row.id,
      name: row.name,
      category: InventoryCategory.values.byName(row.category),
      unit: row.unit,
      onHandQuantity: row.onHandQuantity,
      lowStockThreshold: row.lowStockThreshold,
    );
  }

  @override
  Future<String> create({
    required Role role,
    required String name,
    required InventoryCategory category,
    required String unit,
    required int onHandQuantity,
    required int lowStockThreshold,
  }) async {
    requirePermission(role, Permission.canManageInventory);

    if (onHandQuantity < 0) {
      throw const InventoryValidationException(
        'On-hand quantity cannot be negative.',
      );
    }
    if (lowStockThreshold < 0) {
      throw const InventoryValidationException(
        'Low-stock threshold cannot be negative.',
      );
    }

    final String id = _uuid.v4();
    final DateTime now = DateTime.now().toUtc();
    await _db
        .into(_db.inventoryItems)
        .insert(
          InventoryItemsCompanion.insert(
            id: id,
            name: name.trim(),
            category: category.name,
            unit: unit.trim(),
            onHandQuantity: onHandQuantity,
            lowStockThreshold: lowStockThreshold,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  @override
  Future<String> recordRestock({
    required Role role,
    required String actorUserId,
    required String inventoryItemId,
    required int quantityAdded,
    DateTime? restockDate,
    String? supplier,
    String? notes,
  }) async {
    requirePermission(role, Permission.canManageInventory);

    if (quantityAdded <= 0) {
      throw const InventoryValidationException(
        'Quantity added must be positive.',
      );
    }

    final String id = _uuid.v4();
    final DateTime now = DateTime.now().toUtc();

    await _db.transaction(() async {
      await _db
          .into(_db.restockEvents)
          .insert(
            RestockEventsCompanion.insert(
              id: id,
              inventoryItemId: inventoryItemId,
              quantityAdded: quantityAdded,
              restockDate: restockDate ?? now,
              actorUserId: actorUserId,
              supplier: Value(supplier?.trim()),
              notes: Value(notes?.trim()),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final InventoryItemRow item = await (_db.select(
        _db.inventoryItems,
      )..where((InventoryItems t) => t.id.equals(inventoryItemId))).getSingle();

      await (_db.update(
        _db.inventoryItems,
      )..where((InventoryItems t) => t.id.equals(inventoryItemId))).write(
        InventoryItemsCompanion(
          onHandQuantity: Value(item.onHandQuantity + quantityAdded),
          updatedAt: Value(now),
        ),
      );
    });

    return id;
  }

  @override
  Stream<List<RestockEvent>> watchRestockHistory({
    required Role role,
    required String inventoryItemId,
  }) {
    requirePermission(role, Permission.canViewInventory);

    final SimpleSelectStatement<$RestockEventsTable, RestockEventRow> select =
        _db.select(_db.restockEvents)
          ..where(
            (RestockEvents t) => t.inventoryItemId.equals(inventoryItemId),
          )
          ..orderBy([(RestockEvents t) => OrderingTerm.asc(t.createdAt)]);

    return select.watch().map(
      (List<RestockEventRow> rows) => rows
          .map(
            (RestockEventRow row) => RestockEvent(
              id: row.id,
              inventoryItemId: row.inventoryItemId,
              quantityAdded: row.quantityAdded,
              restockDate: row.restockDate,
              actorUserId: row.actorUserId,
              recordedAt: row.createdAt,
              supplier: row.supplier,
              notes: row.notes,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<String> adjustStock({
    required Role role,
    required String actorUserId,
    required String inventoryItemId,
    required int newQuantity,
    required String reason,
  }) async {
    requirePermission(role, Permission.canManageInventory);

    final String trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw const InventoryValidationException(
        'A reason is required to adjust stock.',
      );
    }
    if (newQuantity < 0) {
      throw const InventoryValidationException(
        'On-hand quantity cannot be negative.',
      );
    }

    final String id = _uuid.v4();
    final DateTime now = DateTime.now().toUtc();

    await _db.transaction(() async {
      final InventoryItemRow item = await (_db.select(
        _db.inventoryItems,
      )..where((InventoryItems t) => t.id.equals(inventoryItemId))).getSingle();

      await _db
          .into(_db.stockAdjustments)
          .insert(
            StockAdjustmentsCompanion.insert(
              id: id,
              inventoryItemId: inventoryItemId,
              oldQuantity: item.onHandQuantity,
              newQuantity: newQuantity,
              delta: newQuantity - item.onHandQuantity,
              reason: trimmedReason,
              actorUserId: actorUserId,
              createdAt: now,
              updatedAt: now,
            ),
          );

      await (_db.update(
        _db.inventoryItems,
      )..where((InventoryItems t) => t.id.equals(inventoryItemId))).write(
        InventoryItemsCompanion(
          onHandQuantity: Value(newQuantity),
          updatedAt: Value(now),
        ),
      );
    });

    return id;
  }

  @override
  Stream<List<StockAdjustment>> watchAdjustmentHistory({
    required Role role,
    required String inventoryItemId,
  }) {
    requirePermission(role, Permission.canViewInventory);

    final SimpleSelectStatement<$StockAdjustmentsTable, StockAdjustmentRow>
    select = _db.select(_db.stockAdjustments)
      ..where((StockAdjustments t) => t.inventoryItemId.equals(inventoryItemId))
      ..orderBy([(StockAdjustments t) => OrderingTerm.asc(t.createdAt)]);

    return select.watch().map(
      (List<StockAdjustmentRow> rows) => rows
          .map(
            (StockAdjustmentRow row) => StockAdjustment(
              id: row.id,
              inventoryItemId: row.inventoryItemId,
              oldQuantity: row.oldQuantity,
              newQuantity: row.newQuantity,
              delta: row.delta,
              reason: row.reason,
              actorUserId: row.actorUserId,
              recordedAt: row.createdAt,
            ),
          )
          .toList(growable: false),
    );
  }
}
