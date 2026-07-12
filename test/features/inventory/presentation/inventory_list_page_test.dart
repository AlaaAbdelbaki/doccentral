import 'dart:async';

import 'package:docentral/features/inventory/domain/inventory_category.dart';
import 'package:docentral/features/inventory/domain/inventory_item.dart';
import 'package:docentral/features/inventory/domain/inventory_repository.dart';
import 'package:docentral/features/inventory/presentation/inventory_list_page.dart';
import 'package:docentral/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeInventoryRepository implements InventoryRepository {
  _FakeInventoryRepository(List<InventoryItem> items)
    : _items = List<InventoryItem>.of(items);

  final List<InventoryItem> _items;
  final List<InventoryItem> created = <InventoryItem>[];
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<List<InventoryItem>> watchAll({required Role role}) async* {
    yield List<InventoryItem>.of(_items);
    await for (final _ in _changes.stream) {
      yield List<InventoryItem>.of(_items);
    }
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
    final String id = 'new-${_items.length}';
    final InventoryItem item = InventoryItem(
      id: id,
      name: name,
      category: category,
      unit: unit,
      onHandQuantity: onHandQuantity,
      lowStockThreshold: lowStockThreshold,
    );
    _items.add(item);
    created.add(item);
    _changes.add(null);
    return id;
  }
}

Future<_FakeInventoryRepository> _pumpPage(
  WidgetTester tester, {
  List<InventoryItem> items = const <InventoryItem>[],
  Role role = Role.assistant,
}) async {
  final _FakeInventoryRepository fakeRepository = _FakeInventoryRepository(
    items,
  );
  addTearDown(() => fakeRepository._changes.close());
  final ProviderContainer container = ProviderContainer(
    overrides: [inventoryRepositoryProvider.overrideWithValue(fakeRepository)],
  );
  addTearDown(container.dispose);
  container.read(currentRoleProvider.notifier).setRole(role);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: InventoryListPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return fakeRepository;
}

void main() {
  testWidgets('shows the empty state when there are no items', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester);

    expect(find.text('No inventory items yet'), findsOneWidget);
  });

  testWidgets(
    'groups items by category with name, unit, on-hand, and threshold',
    (WidgetTester tester) async {
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
            onHandQuantity: 3,
            lowStockThreshold: 2,
          ),
        ],
      );

      expect(find.text('Supply'), findsOneWidget);
      expect(find.text('Cleaning'), findsOneWidget);
      expect(find.text('Gauze'), findsOneWidget);
      expect(find.text('Bleach'), findsOneWidget);
      expect(find.text('box of 100'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
    },
  );

  testWidgets(
    'shows a low-stock indicator when on-hand is at or under the threshold',
    (WidgetTester tester) async {
      await _pumpPage(
        tester,
        items: const <InventoryItem>[
          InventoryItem(
            id: '1',
            name: 'Bleach',
            category: InventoryCategory.cleaning,
            unit: 'bottle',
            onHandQuantity: 2,
            lowStockThreshold: 2,
          ),
        ],
      );

      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    },
  );

  testWidgets('the Add item button is hidden for a Nurse', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, role: Role.nurse);

    expect(find.text('Add item'), findsNothing);
  });

  testWidgets('creating an item via the form dialog adds it to the list', (
    WidgetTester tester,
  ) async {
    final _FakeInventoryRepository fakeRepository = await _pumpPage(tester);

    await tester.tap(find.text('Add item'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Gauze');
    await tester.enterText(find.widgetWithText(TextFormField, 'Unit'), 'box');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'On-hand quantity'),
      '10',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Low-stock threshold'),
      '2',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(fakeRepository.created.single.name, 'Gauze');
    expect(fakeRepository.created.single.unit, 'box');
    expect(fakeRepository.created.single.onHandQuantity, 10);
    expect(fakeRepository.created.single.lowStockThreshold, 2);
    expect(find.text('Gauze'), findsOneWidget);
  });

  testWidgets(
    'submitting a negative low-stock threshold shows a validation error',
    (WidgetTester tester) async {
      final _FakeInventoryRepository fakeRepository = await _pumpPage(tester);

      await tester.tap(find.text('Add item'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Gauze',
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'Unit'), 'box');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'On-hand quantity'),
        '10',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Low-stock threshold'),
        '-1',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.text('Low-stock threshold cannot be negative'),
        findsOneWidget,
      );
      expect(fakeRepository.created, isEmpty);
    },
  );
}
