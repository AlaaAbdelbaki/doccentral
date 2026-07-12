import 'package:docentral/features/inventory/domain/inventory_category.dart';
import 'package:docentral/features/inventory/domain/inventory_exceptions.dart';
import 'package:docentral/features/inventory/domain/inventory_item.dart';
import 'package:docentral/features/inventory/domain/inventory_repository.dart';
import 'package:docentral/shared/data/database/app_database.dart';
import 'package:docentral/shared/data/database/tables/inventory_items_table.dart';
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
}
