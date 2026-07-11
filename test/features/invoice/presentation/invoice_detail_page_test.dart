import 'dart:async';

import 'package:docentral/features/invoice/domain/invoice_adjustment_type.dart';
import 'package:docentral/features/invoice/domain/invoice_exceptions.dart';
import 'package:docentral/features/invoice/domain/invoice_item.dart';
import 'package:docentral/features/invoice/domain/invoice_record.dart';
import 'package:docentral/features/invoice/domain/invoice_repository.dart';
import 'package:docentral/features/invoice/domain/invoice_status.dart';
import 'package:docentral/features/invoice/presentation/invoice_detail_page.dart';
import 'package:docentral/features/invoice/presentation/providers/invoice_repository_provider.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/data/providers/current_user_id_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeInvoiceRepository implements InvoiceRepository {
  _FakeInvoiceRepository(this._invoice, List<InvoiceItem> items)
    : _items = List<InvoiceItem>.of(items);

  InvoiceRecord? _invoice;
  final List<InvoiceItem> _items;
  final List<({InvoiceAdjustmentType type, String description, double amount})>
  addedAdjustments =
      <({InvoiceAdjustmentType type, String description, double amount})>[];
  Object? addAdjustmentErrorToThrow;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<InvoiceRecord?> watchInvoiceForVisit({
    required Role role,
    required String visitId,
  }) async* {
    yield _invoice;
    await for (final _ in _changes.stream) {
      yield _invoice;
    }
  }

  @override
  Stream<List<InvoiceItem>> watchItemsForInvoice({
    required Role role,
    required String invoiceId,
  }) async* {
    yield List<InvoiceItem>.of(_items);
    await for (final _ in _changes.stream) {
      yield List<InvoiceItem>.of(_items);
    }
  }

  @override
  Future<String> addAdjustment({
    required Role role,
    required String invoiceId,
    required InvoiceAdjustmentType adjustmentType,
    required String description,
    required double amount,
  }) async {
    if (addAdjustmentErrorToThrow != null) {
      throw addAdjustmentErrorToThrow!;
    }
    addedAdjustments.add((
      type: adjustmentType,
      description: description,
      amount: amount,
    ));
    final String id = 'adjustment-${_items.length}';
    final double signedTotal = adjustmentType == InvoiceAdjustmentType.discount
        ? -amount
        : amount;
    _items.add(
      InvoiceItem(
        id: id,
        invoiceId: invoiceId,
        description: description,
        quantity: 1,
        unitPrice: amount,
        totalPrice: signedTotal,
        adjustmentType: adjustmentType,
      ),
    );
    final InvoiceRecord? existing = _invoice;
    if (existing != null) {
      _invoice = InvoiceRecord(
        id: existing.id,
        patientId: existing.patientId,
        visitId: existing.visitId,
        totalAmount: existing.totalAmount + signedTotal,
        status: existing.status,
        createdByUserId: existing.createdByUserId,
      );
    }
    _changes.add(null);
    return id;
  }

  final List<String> finalizedInvoiceIds = <String>[];
  Object? finalizeInvoiceErrorToThrow;

  @override
  Future<void> finalizeInvoice({
    required Role role,
    required String actorUserId,
    required String invoiceId,
  }) async {
    if (finalizeInvoiceErrorToThrow != null) {
      throw finalizeInvoiceErrorToThrow!;
    }
    finalizedInvoiceIds.add(invoiceId);
    final InvoiceRecord? existing = _invoice;
    if (existing != null) {
      _invoice = InvoiceRecord(
        id: existing.id,
        patientId: existing.patientId,
        visitId: existing.visitId,
        totalAmount: existing.totalAmount,
        status: InvoiceStatus.unpaid,
        createdByUserId: existing.createdByUserId,
      );
    }
    _changes.add(null);
  }
}

Future<_FakeInvoiceRepository> _pumpPage(
  WidgetTester tester, {
  required InvoiceRecord? invoice,
  List<InvoiceItem> items = const <InvoiceItem>[],
  Role role = Role.assistant,
}) async {
  final _FakeInvoiceRepository fakeRepository = _FakeInvoiceRepository(
    invoice,
    items,
  );
  addTearDown(() => fakeRepository._changes.close());

  final ProviderContainer container = ProviderContainer(
    overrides: [invoiceRepositoryProvider.overrideWithValue(fakeRepository)],
  );
  addTearDown(container.dispose);
  container.read(currentRoleProvider.notifier).setRole(role);
  container.read(currentUserIdProvider.notifier).setUserId('actor-1');

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: InvoiceDetailPage(visitId: 'visit-1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return fakeRepository;
}

void main() {
  InvoiceRecord draftInvoice() => const InvoiceRecord(
    id: 'invoice-1',
    patientId: 'patient-1',
    visitId: 'visit-1',
    totalAmount: 100,
    status: InvoiceStatus.draft,
    createdByUserId: 'dentist-1',
  );

  InvoiceItem treatmentItem() => const InvoiceItem(
    id: 'item-1',
    invoiceId: 'invoice-1',
    description: 'Filling',
    toothNumber: '18',
    quantity: 2,
    unitPrice: 50,
    totalPrice: 100,
  );

  testWidgets('shows the invoice total and its items', (
    WidgetTester tester,
  ) async {
    await _pumpPage(
      tester,
      invoice: draftInvoice(),
      items: <InvoiceItem>[treatmentItem()],
    );

    expect(find.textContaining('100'), findsWidgets);
    expect(find.text('Filling'), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no items', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, invoice: draftInvoice());

    expect(find.text('No items recorded yet'), findsOneWidget);
  });

  testWidgets('Add adjustment button is hidden for a Nurse', (
    WidgetTester tester,
  ) async {
    await _pumpPage(
      tester,
      invoice: draftInvoice(),
      items: <InvoiceItem>[treatmentItem()],
      role: Role.nurse,
    );

    expect(find.text('Add adjustment'), findsNothing);
  });

  testWidgets(
    'Add adjustment button is hidden once the invoice is no longer draft',
    (WidgetTester tester) async {
      const InvoiceRecord nonDraft = InvoiceRecord(
        id: 'invoice-1',
        patientId: 'patient-1',
        visitId: 'visit-1',
        totalAmount: 100,
        status: InvoiceStatus.unpaid,
        createdByUserId: 'dentist-1',
      );

      await _pumpPage(
        tester,
        invoice: nonDraft,
        items: <InvoiceItem>[treatmentItem()],
      );

      expect(find.text('Add adjustment'), findsNothing);
    },
  );

  testWidgets(
    'submitting the adjustment dialog calls addAdjustment and updates the '
    'list and total',
    (WidgetTester tester) async {
      final _FakeInvoiceRepository fakeRepository = await _pumpPage(
        tester,
        invoice: draftInvoice(),
        items: <InvoiceItem>[treatmentItem()],
      );

      await tester.tap(find.text('Add adjustment'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description'),
        'Loyalty discount',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'),
        '20',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(fakeRepository.addedAdjustments.length, 1);
      expect(
        fakeRepository.addedAdjustments.single.type,
        InvoiceAdjustmentType.discount,
      );
      expect(
        fakeRepository.addedAdjustments.single.description,
        'Loyalty discount',
      );
      expect(fakeRepository.addedAdjustments.single.amount, 20);
      expect(find.text('Loyalty discount'), findsOneWidget);
      expect(find.textContaining('80'), findsWidgets);
    },
  );

  testWidgets('shows an error snackbar when the invoice is no longer draft', (
    WidgetTester tester,
  ) async {
    final _FakeInvoiceRepository fakeRepository = await _pumpPage(
      tester,
      invoice: draftInvoice(),
      items: <InvoiceItem>[treatmentItem()],
    );
    fakeRepository.addAdjustmentErrorToThrow = const InvoiceNotDraftException();

    await tester.tap(find.text('Add adjustment'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description'),
      'Too late',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '10');
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('This invoice can no longer be adjusted.'),
      findsOneWidget,
    );
  });

  testWidgets('rejects a non-positive amount before calling addAdjustment', (
    WidgetTester tester,
  ) async {
    final _FakeInvoiceRepository fakeRepository = await _pumpPage(
      tester,
      invoice: draftInvoice(),
      items: <InvoiceItem>[treatmentItem()],
    );

    await tester.tap(find.text('Add adjustment'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description'),
      'Invalid',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a positive amount'), findsOneWidget);
    expect(fakeRepository.addedAdjustments, isEmpty);
  });

  testWidgets('Finalize invoice button is hidden for a Nurse', (
    WidgetTester tester,
  ) async {
    await _pumpPage(
      tester,
      invoice: draftInvoice(),
      items: <InvoiceItem>[treatmentItem()],
      role: Role.nurse,
    );

    expect(find.text('Finalize invoice'), findsNothing);
  });

  testWidgets(
    'Finalize invoice button is hidden once the invoice is no longer draft',
    (WidgetTester tester) async {
      const InvoiceRecord nonDraft = InvoiceRecord(
        id: 'invoice-1',
        patientId: 'patient-1',
        visitId: 'visit-1',
        totalAmount: 100,
        status: InvoiceStatus.unpaid,
        createdByUserId: 'dentist-1',
      );

      await _pumpPage(
        tester,
        invoice: nonDraft,
        items: <InvoiceItem>[treatmentItem()],
      );

      expect(find.text('Finalize invoice'), findsNothing);
    },
  );

  testWidgets('cancelling the finalize dialog does not call finalizeInvoice', (
    WidgetTester tester,
  ) async {
    final _FakeInvoiceRepository fakeRepository = await _pumpPage(
      tester,
      invoice: draftInvoice(),
      items: <InvoiceItem>[treatmentItem()],
    );

    await tester.tap(find.text('Finalize invoice'));
    await tester.pumpAndSettle();

    expect(find.text('Finalize this invoice?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(fakeRepository.finalizedInvoiceIds, isEmpty);
  });

  testWidgets(
    'confirming Finalize invoice calls finalizeInvoice and shows a success '
    'snackbar',
    (WidgetTester tester) async {
      final _FakeInvoiceRepository fakeRepository = await _pumpPage(
        tester,
        invoice: draftInvoice(),
        items: <InvoiceItem>[treatmentItem()],
      );

      await tester.tap(find.text('Finalize invoice'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeRepository.finalizedInvoiceIds, <String>['invoice-1']);
      expect(find.text('Invoice finalized.'), findsOneWidget);
      expect(find.text('Finalize invoice'), findsNothing);
      expect(find.text('Add adjustment'), findsNothing);
    },
  );

  testWidgets(
    'shows an error snackbar when finalizing an invoice that is no longer '
    'draft',
    (WidgetTester tester) async {
      final _FakeInvoiceRepository fakeRepository = await _pumpPage(
        tester,
        invoice: draftInvoice(),
        items: <InvoiceItem>[treatmentItem()],
      );
      fakeRepository.finalizeInvoiceErrorToThrow =
          const InvoiceNotDraftException();

      await tester.tap(find.text('Finalize invoice'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('This invoice can no longer be adjusted.'),
        findsOneWidget,
      );
    },
  );
}
