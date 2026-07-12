import 'package:docentral/features/inventory/domain/inventory_category.dart';
import 'package:docentral/features/inventory/domain/inventory_item.dart';
import 'package:docentral/features/inventory/domain/inventory_repository.dart';
import 'package:docentral/features/inventory/domain/restock_event.dart';
import 'package:docentral/features/inventory/domain/stock_adjustment.dart';
import 'package:docentral/features/inventory/presentation/low_stock_page.dart';
import 'package:docentral/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeInventoryRepository implements InventoryRepository {
  _FakeInventoryRepository(this._items);

  final List<InventoryItem> _items;

  @override
  Stream<List<InventoryItem>> watchAll({required Role role}) =>
      Stream.value(_items);

  @override
  Future<String> create({
    required Role role,
    required String name,
    required InventoryCategory category,
    required String unit,
    required int onHandQuantity,
    required int lowStockThreshold,
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Future<String> recordRestock({
    required Role role,
    required String actorUserId,
    required String inventoryItemId,
    required int quantityAdded,
    DateTime? restockDate,
    String? supplier,
    String? notes,
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Stream<List<RestockEvent>> watchRestockHistory({
    required Role role,
    required String inventoryItemId,
  }) => Stream.value(const <RestockEvent>[]);

  @override
  Future<String> adjustStock({
    required Role role,
    required String actorUserId,
    required String inventoryItemId,
    required int newQuantity,
    required String reason,
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Stream<List<StockAdjustment>> watchAdjustmentHistory({
    required Role role,
    required String inventoryItemId,
  }) => Stream.value(const <StockAdjustment>[]);
}

Future<void> _pumpPage(
  WidgetTester tester, {
  List<InventoryItem> items = const <InventoryItem>[],
}) async {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      inventoryRepositoryProvider.overrideWithValue(
        _FakeInventoryRepository(items),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.read(currentRoleProvider.notifier).setRole(Role.assistant);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LowStockPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the empty state when no items are low on stock', (
    WidgetTester tester,
  ) async {
    await _pumpPage(
      tester,
      items: const <InventoryItem>[
        InventoryItem(
          id: '1',
          name: 'Gauze',
          category: InventoryCategory.supply,
          unit: 'box of 100',
          onHandQuantity: 20,
          lowStockThreshold: 5,
        ),
      ],
    );

    expect(find.text('No items are low on stock'), findsOneWidget);
  });

  testWidgets('lists only items at or under their low-stock threshold', (
    WidgetTester tester,
  ) async {
    await _pumpPage(
      tester,
      items: const <InventoryItem>[
        InventoryItem(
          id: '1',
          name: 'Gauze',
          category: InventoryCategory.supply,
          unit: 'box of 100',
          onHandQuantity: 20,
          lowStockThreshold: 5,
        ),
        InventoryItem(
          id: '2',
          name: 'Bleach',
          category: InventoryCategory.cleaning,
          unit: 'bottle',
          onHandQuantity: 2,
          lowStockThreshold: 2,
        ),
      ],
    );

    expect(find.text('Gauze'), findsNothing);
    expect(find.text('Bleach'), findsOneWidget);
  });
}
