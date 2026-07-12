import 'dart:async';

import 'package:docentral/features/invoice/domain/invoice_adjustment_type.dart';
import 'package:docentral/features/invoice/domain/invoice_exceptions.dart';
import 'package:docentral/features/invoice/domain/invoice_item.dart';
import 'package:docentral/features/invoice/domain/invoice_record.dart';
import 'package:docentral/features/invoice/domain/invoice_repository.dart';
import 'package:docentral/features/invoice/domain/invoice_status.dart';
import 'package:docentral/features/invoice/domain/patient_balance.dart';
import 'package:docentral/features/invoice/domain/payment.dart';
import 'package:docentral/features/invoice/domain/payment_exceptions.dart';
import 'package:docentral/features/invoice/domain/payment_method.dart';
import 'package:docentral/features/invoice/domain/payment_repository.dart';
import 'package:docentral/features/invoice/presentation/invoice_detail_page.dart';
import 'package:docentral/features/invoice/presentation/providers/invoice_repository_provider.dart';
import 'package:docentral/features/invoice/presentation/providers/payment_repository_provider.dart';
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

  final List<({String invoiceId, String reason})> voidedInvoices =
      <({String invoiceId, String reason})>[];
  Object? voidInvoiceErrorToThrow;

  @override
  Future<void> voidInvoice({
    required Role role,
    required String actorUserId,
    required String invoiceId,
    required String reason,
  }) async {
    if (voidInvoiceErrorToThrow != null) {
      throw voidInvoiceErrorToThrow!;
    }
    voidedInvoices.add((invoiceId: invoiceId, reason: reason));
    final InvoiceRecord? existing = _invoice;
    if (existing != null) {
      _invoice = InvoiceRecord(
        id: existing.id,
        patientId: existing.patientId,
        visitId: existing.visitId,
        totalAmount: existing.totalAmount,
        status: InvoiceStatus.voided,
        createdByUserId: existing.createdByUserId,
      );
    }
    _changes.add(null);
  }

  @override
  Stream<double> watchOutstandingBalanceForPatient({
    required Role role,
    required String patientId,
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Stream<List<PatientBalance>> watchPatientsWithBalance({required Role role}) =>
      throw UnimplementedError('not exercised by this test');
}

class _FakePaymentRepository implements PaymentRepository {
  _FakePaymentRepository(List<Payment> payments)
    : _payments = List<Payment>.of(payments);

  final List<Payment> _payments;
  final List<
    ({double amount, PaymentMethod method, DateTime paymentDate, String? notes})
  >
  recordedPayments =
      <
        ({
          double amount,
          PaymentMethod method,
          DateTime paymentDate,
          String? notes,
        })
      >[];
  Object? recordPaymentErrorToThrow;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<List<Payment>> watchPaymentsForInvoice({
    required Role role,
    required String invoiceId,
  }) async* {
    yield List<Payment>.of(_payments);
    await for (final _ in _changes.stream) {
      yield List<Payment>.of(_payments);
    }
  }

  @override
  Future<String> recordPayment({
    required Role role,
    required String actorUserId,
    required String invoiceId,
    required double amount,
    PaymentMethod method = PaymentMethod.cash,
    DateTime? paymentDate,
    String? notes,
  }) async {
    if (recordPaymentErrorToThrow != null) {
      throw recordPaymentErrorToThrow!;
    }
    final DateTime resolvedDate = paymentDate ?? DateTime.now();
    recordedPayments.add((
      amount: amount,
      method: method,
      paymentDate: resolvedDate,
      notes: notes,
    ));
    final String id = 'payment-${_payments.length}';
    _payments.add(
      Payment(
        id: id,
        invoiceId: invoiceId,
        amount: amount,
        method: method,
        paymentDate: resolvedDate,
        recordedByUserId: actorUserId,
        notes: notes,
      ),
    );
    _changes.add(null);
    return id;
  }
}

Future<({_FakeInvoiceRepository invoice, _FakePaymentRepository payment})>
_pumpPage(
  WidgetTester tester, {
  required InvoiceRecord? invoice,
  List<InvoiceItem> items = const <InvoiceItem>[],
  List<Payment> payments = const <Payment>[],
  Role role = Role.assistant,
}) async {
  final _FakeInvoiceRepository fakeInvoiceRepository = _FakeInvoiceRepository(
    invoice,
    items,
  );
  addTearDown(() => fakeInvoiceRepository._changes.close());
  final _FakePaymentRepository fakePaymentRepository = _FakePaymentRepository(
    payments,
  );
  addTearDown(() => fakePaymentRepository._changes.close());

  final ProviderContainer container = ProviderContainer(
    overrides: [
      invoiceRepositoryProvider.overrideWithValue(fakeInvoiceRepository),
      paymentRepositoryProvider.overrideWithValue(fakePaymentRepository),
    ],
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
  return (invoice: fakeInvoiceRepository, payment: fakePaymentRepository);
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
      final _FakeInvoiceRepository fakeRepository = (await _pumpPage(
        tester,
        invoice: draftInvoice(),
        items: <InvoiceItem>[treatmentItem()],
      )).invoice;

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
    final _FakeInvoiceRepository fakeRepository = (await _pumpPage(
      tester,
      invoice: draftInvoice(),
      items: <InvoiceItem>[treatmentItem()],
    )).invoice;
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
    final _FakeInvoiceRepository fakeRepository = (await _pumpPage(
      tester,
      invoice: draftInvoice(),
      items: <InvoiceItem>[treatmentItem()],
    )).invoice;

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
    final _FakeInvoiceRepository fakeRepository = (await _pumpPage(
      tester,
      invoice: draftInvoice(),
      items: <InvoiceItem>[treatmentItem()],
    )).invoice;

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
      final _FakeInvoiceRepository fakeRepository = (await _pumpPage(
        tester,
        invoice: draftInvoice(),
        items: <InvoiceItem>[treatmentItem()],
      )).invoice;

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
      final _FakeInvoiceRepository fakeRepository = (await _pumpPage(
        tester,
        invoice: draftInvoice(),
        items: <InvoiceItem>[treatmentItem()],
      )).invoice;
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

  testWidgets('shows the invoice status and the empty payments state', (
    WidgetTester tester,
  ) async {
    await _pumpPage(
      tester,
      invoice: draftInvoice(),
      items: <InvoiceItem>[treatmentItem()],
    );

    expect(find.textContaining('Draft'), findsOneWidget);
    expect(find.text('No payments recorded yet'), findsOneWidget);
  });

  testWidgets('shows recorded payments', (WidgetTester tester) async {
    final Payment payment = Payment(
      id: 'payment-1',
      invoiceId: 'invoice-1',
      amount: 40,
      method: PaymentMethod.cash,
      paymentDate: DateTime(2026, 1, 15),
      recordedByUserId: 'assistant-1',
      notes: 'Paid in full for the visit',
    );

    await _pumpPage(
      tester,
      invoice: draftInvoice(),
      items: <InvoiceItem>[treatmentItem()],
      payments: <Payment>[payment],
    );

    expect(find.textContaining('Cash'), findsOneWidget);
    expect(find.text('Paid in full for the visit'), findsOneWidget);
  });

  testWidgets('Record payment button is hidden for a Nurse', (
    WidgetTester tester,
  ) async {
    await _pumpPage(
      tester,
      invoice: draftInvoice(),
      items: <InvoiceItem>[treatmentItem()],
      role: Role.nurse,
    );

    expect(find.text('Record payment'), findsNothing);
  });

  testWidgets('Record payment button is hidden once the invoice is voided', (
    WidgetTester tester,
  ) async {
    const InvoiceRecord voided = InvoiceRecord(
      id: 'invoice-1',
      patientId: 'patient-1',
      visitId: 'visit-1',
      totalAmount: 100,
      status: InvoiceStatus.voided,
      createdByUserId: 'dentist-1',
    );

    await _pumpPage(
      tester,
      invoice: voided,
      items: <InvoiceItem>[treatmentItem()],
    );

    expect(find.text('Record payment'), findsNothing);
  });

  testWidgets('submitting the payment dialog calls recordPayment and shows a '
      'success snackbar', (WidgetTester tester) async {
    final fakePaymentRepository = (await _pumpPage(
      tester,
      invoice: draftInvoice(),
      items: <InvoiceItem>[treatmentItem()],
    )).payment;

    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '40');
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(fakePaymentRepository.recordedPayments.length, 1);
    expect(fakePaymentRepository.recordedPayments.single.amount, 40);
    expect(
      fakePaymentRepository.recordedPayments.single.method,
      PaymentMethod.cash,
    );
    expect(find.text('Payment recorded.'), findsOneWidget);
  });

  testWidgets('rejects a non-positive amount before calling recordPayment', (
    WidgetTester tester,
  ) async {
    final fakePaymentRepository = (await _pumpPage(
      tester,
      invoice: draftInvoice(),
      items: <InvoiceItem>[treatmentItem()],
    )).payment;

    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a positive amount'), findsOneWidget);
    expect(fakePaymentRepository.recordedPayments, isEmpty);
  });

  testWidgets(
    'shows an error snackbar when recording a payment on a voided invoice',
    (WidgetTester tester) async {
      const InvoiceRecord unpaid = InvoiceRecord(
        id: 'invoice-1',
        patientId: 'patient-1',
        visitId: 'visit-1',
        totalAmount: 100,
        status: InvoiceStatus.unpaid,
        createdByUserId: 'dentist-1',
      );
      final fakePaymentRepository = (await _pumpPage(
        tester,
        invoice: unpaid,
        items: <InvoiceItem>[treatmentItem()],
      )).payment;
      fakePaymentRepository.recordPaymentErrorToThrow =
          const PaymentInvoiceVoidedException();

      await tester.tap(find.text('Record payment'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'),
        '40',
      );
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text(
          'This invoice has been voided. No further payments can be recorded.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('Void invoice button is hidden for an Assistant', (
    WidgetTester tester,
  ) async {
    await _pumpPage(
      tester,
      invoice: draftInvoice(),
      items: <InvoiceItem>[treatmentItem()],
    );

    expect(find.text('Void invoice'), findsNothing);
  });

  testWidgets('Void invoice button is hidden once the invoice is voided', (
    WidgetTester tester,
  ) async {
    const InvoiceRecord voided = InvoiceRecord(
      id: 'invoice-1',
      patientId: 'patient-1',
      visitId: 'visit-1',
      totalAmount: 100,
      status: InvoiceStatus.voided,
      createdByUserId: 'dentist-1',
    );

    await _pumpPage(
      tester,
      invoice: voided,
      items: <InvoiceItem>[treatmentItem()],
      role: Role.doctor,
    );

    expect(find.text('Void invoice'), findsNothing);
  });

  testWidgets('cancelling the void dialog does not call voidInvoice', (
    WidgetTester tester,
  ) async {
    final fakeInvoiceRepository = (await _pumpPage(
      tester,
      invoice: draftInvoice(),
      items: <InvoiceItem>[treatmentItem()],
      role: Role.doctor,
    )).invoice;

    await tester.tap(find.text('Void invoice'));
    await tester.pumpAndSettle();

    expect(find.text('Void this invoice?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(fakeInvoiceRepository.voidedInvoices, isEmpty);
  });

  testWidgets('confirming with a blank reason shows a validation error', (
    WidgetTester tester,
  ) async {
    final fakeInvoiceRepository = (await _pumpPage(
      tester,
      invoice: draftInvoice(),
      items: <InvoiceItem>[treatmentItem()],
      role: Role.doctor,
    )).invoice;

    await tester.tap(find.text('Void invoice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(
      find.text('A reason is required to void this invoice.'),
      findsOneWidget,
    );
    expect(fakeInvoiceRepository.voidedInvoices, isEmpty);
  });

  testWidgets(
    'confirming Void invoice with a reason calls voidInvoice and shows a '
    'success snackbar',
    (WidgetTester tester) async {
      final fakeInvoiceRepository = (await _pumpPage(
        tester,
        invoice: draftInvoice(),
        items: <InvoiceItem>[treatmentItem()],
        role: Role.doctor,
      )).invoice;

      await tester.tap(find.text('Void invoice'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Reason'),
        'Billed to the wrong patient',
      );
      await tester.tap(find.text('Confirm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        fakeInvoiceRepository.voidedInvoices,
        <({String invoiceId, String reason})>[
          (invoiceId: 'invoice-1', reason: 'Billed to the wrong patient'),
        ],
      );
      expect(find.text('Invoice voided.'), findsOneWidget);
      expect(find.text('Void invoice'), findsNothing);
    },
  );

  testWidgets('shows an error snackbar when the invoice is already voided', (
    WidgetTester tester,
  ) async {
    final fakeInvoiceRepository = (await _pumpPage(
      tester,
      invoice: draftInvoice(),
      items: <InvoiceItem>[treatmentItem()],
      role: Role.doctor,
    )).invoice;
    fakeInvoiceRepository.voidInvoiceErrorToThrow =
        const InvoiceAlreadyVoidedException();

    await tester.tap(find.text('Void invoice'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Reason'),
      'Test reason',
    );
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('This invoice has already been voided.'), findsOneWidget);
  });

  testWidgets('shows refund owed on a voided invoice with prior payments', (
    WidgetTester tester,
  ) async {
    const InvoiceRecord voided = InvoiceRecord(
      id: 'invoice-1',
      patientId: 'patient-1',
      visitId: 'visit-1',
      totalAmount: 100,
      status: InvoiceStatus.voided,
      createdByUserId: 'dentist-1',
    );
    final Payment payment = Payment(
      id: 'payment-1',
      invoiceId: 'invoice-1',
      amount: 40,
      method: PaymentMethod.cash,
      paymentDate: DateTime(2026, 1, 15),
      recordedByUserId: 'assistant-1',
    );

    await _pumpPage(
      tester,
      invoice: voided,
      items: <InvoiceItem>[treatmentItem()],
      payments: <Payment>[payment],
    );

    expect(find.textContaining('Refund owed'), findsOneWidget);
  });

  testWidgets(
    'does not show refund owed on a voided invoice with no prior payments',
    (WidgetTester tester) async {
      const InvoiceRecord voided = InvoiceRecord(
        id: 'invoice-1',
        patientId: 'patient-1',
        visitId: 'visit-1',
        totalAmount: 100,
        status: InvoiceStatus.voided,
        createdByUserId: 'dentist-1',
      );

      await _pumpPage(
        tester,
        invoice: voided,
        items: <InvoiceItem>[treatmentItem()],
      );

      expect(find.textContaining('Refund owed'), findsNothing);
    },
  );
}
