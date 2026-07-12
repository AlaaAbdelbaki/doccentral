import 'package:docentral/features/inventory/data/inventory_repository_impl.dart';
import 'package:docentral/features/inventory/domain/inventory_category.dart';
import 'package:docentral/features/inventory/domain/inventory_exceptions.dart';
import 'package:docentral/features/inventory/domain/inventory_item.dart';
import 'package:docentral/features/inventory/domain/restock_event.dart';
import 'package:docentral/shared/data/database/app_database.dart';
import 'package:docentral/shared/domain/exceptions/permission_denied_exception.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _createInMemoryDatabase() {
  return AppDatabase(NativeDatabase.memory());
}

void main() {
  late AppDatabase db;
  late InventoryRepositoryImpl repository;

  setUp(() {
    db = _createInMemoryDatabase();
    repository = InventoryRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('InventoryRepositoryImpl.create', () {
    test('creates an item queryable via watchAll', () async {
      final String id = await repository.create(
        role: Role.assistant,
        name: 'Gauze',
        category: InventoryCategory.supply,
        unit: 'box of 100',
        onHandQuantity: 20,
        lowStockThreshold: 5,
      );

      final List<InventoryItem> items = await repository
          .watchAll(role: Role.assistant)
          .first;

      expect(items.single.id, id);
      expect(items.single.name, 'Gauze');
      expect(items.single.category, InventoryCategory.supply);
      expect(items.single.unit, 'box of 100');
      expect(items.single.onHandQuantity, 20);
      expect(items.single.lowStockThreshold, 5);
    });

    test(
      'throws InventoryValidationException for a negative on-hand quantity',
      () async {
        expect(
          () => repository.create(
            role: Role.assistant,
            name: 'Gauze',
            category: InventoryCategory.supply,
            unit: 'box of 100',
            onHandQuantity: -1,
            lowStockThreshold: 5,
          ),
          throwsA(isA<InventoryValidationException>()),
        );
      },
    );

    test(
      'throws InventoryValidationException for a negative low-stock threshold',
      () async {
        expect(
          () => repository.create(
            role: Role.assistant,
            name: 'Gauze',
            category: InventoryCategory.supply,
            unit: 'box of 100',
            onHandQuantity: 20,
            lowStockThreshold: -1,
          ),
          throwsA(isA<InventoryValidationException>()),
        );
      },
    );

    test('throws PermissionDeniedException for a Nurse', () async {
      expect(
        () => repository.create(
          role: Role.nurse,
          name: 'Gauze',
          category: InventoryCategory.supply,
          unit: 'box of 100',
          onHandQuantity: 20,
          lowStockThreshold: 5,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });
  });

  group('InventoryRepositoryImpl.watchAll', () {
    test('all three roles can view inventory items', () async {
      await repository.create(
        role: Role.assistant,
        name: 'Gauze',
        category: InventoryCategory.supply,
        unit: 'box of 100',
        onHandQuantity: 20,
        lowStockThreshold: 5,
      );

      for (final Role role in Role.values) {
        final List<InventoryItem> items = await repository
            .watchAll(role: role)
            .first;
        expect(items, hasLength(1), reason: '$role');
      }
    });
  });

  group('InventoryRepositoryImpl.recordRestock', () {
    test(
      'increases on-hand quantity by the recorded amount and logs the event',
      () async {
        final String itemId = await repository.create(
          role: Role.assistant,
          name: 'Gauze',
          category: InventoryCategory.supply,
          unit: 'box of 100',
          onHandQuantity: 20,
          lowStockThreshold: 5,
        );
        final DateTime restockDate = DateTime(2026, 6, 8);

        final String eventId = await repository.recordRestock(
          role: Role.assistant,
          actorUserId: 'actor-1',
          inventoryItemId: itemId,
          quantityAdded: 15,
          restockDate: restockDate,
          supplier: 'Acme Supplies',
          notes: 'Monthly order',
        );

        final InventoryItem item =
            (await repository.watchAll(role: Role.assistant).first).single;
        expect(item.onHandQuantity, 35);

        final List<RestockEvent> history = await repository
            .watchRestockHistory(role: Role.assistant, inventoryItemId: itemId)
            .first;
        expect(history.single.id, eventId);
        expect(history.single.quantityAdded, 15);
        expect(history.single.restockDate, restockDate);
        expect(history.single.actorUserId, 'actor-1');
        expect(history.single.supplier, 'Acme Supplies');
        expect(history.single.notes, 'Monthly order');
      },
    );

    test(
      'on_hand after restock equals previous on_hand plus quantity added, across multiple restocks',
      () async {
        final String itemId = await repository.create(
          role: Role.assistant,
          name: 'Gauze',
          category: InventoryCategory.supply,
          unit: 'box of 100',
          onHandQuantity: 20,
          lowStockThreshold: 5,
        );

        await repository.recordRestock(
          role: Role.assistant,
          actorUserId: 'actor-1',
          inventoryItemId: itemId,
          quantityAdded: 10,
        );
        await repository.recordRestock(
          role: Role.assistant,
          actorUserId: 'actor-1',
          inventoryItemId: itemId,
          quantityAdded: 5,
        );

        final InventoryItem item =
            (await repository.watchAll(role: Role.assistant).first).single;
        expect(item.onHandQuantity, 35);

        final List<RestockEvent> history = await repository
            .watchRestockHistory(role: Role.assistant, inventoryItemId: itemId)
            .first;
        expect(history, hasLength(2));
      },
    );

    test(
      'throws InventoryValidationException for a zero or negative quantity',
      () async {
        final String itemId = await repository.create(
          role: Role.assistant,
          name: 'Gauze',
          category: InventoryCategory.supply,
          unit: 'box of 100',
          onHandQuantity: 20,
          lowStockThreshold: 5,
        );

        expect(
          () => repository.recordRestock(
            role: Role.assistant,
            actorUserId: 'actor-1',
            inventoryItemId: itemId,
            quantityAdded: 0,
          ),
          throwsA(isA<InventoryValidationException>()),
        );
      },
    );

    test('throws PermissionDeniedException for a Nurse', () async {
      final String itemId = await repository.create(
        role: Role.assistant,
        name: 'Gauze',
        category: InventoryCategory.supply,
        unit: 'box of 100',
        onHandQuantity: 20,
        lowStockThreshold: 5,
      );

      expect(
        () => repository.recordRestock(
          role: Role.nurse,
          actorUserId: 'actor-1',
          inventoryItemId: itemId,
          quantityAdded: 10,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });
  });
}
