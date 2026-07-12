import 'package:docentral/features/invoice/data/payment_repository_impl.dart';
import 'package:docentral/features/invoice/domain/invoice_status.dart';
import 'package:docentral/features/invoice/domain/payment_exceptions.dart';
import 'package:docentral/features/invoice/domain/payment_method.dart';
import 'package:docentral/shared/data/database/app_database.dart';
import 'package:docentral/shared/domain/exceptions/permission_denied_exception.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

AppDatabase _createInMemoryDatabase() {
  return AppDatabase(NativeDatabase.memory());
}

void main() {
  late AppDatabase db;
  late PaymentRepositoryImpl repository;
  const Uuid uuid = Uuid();

  setUp(() {
    db = _createInMemoryDatabase();
    repository = PaymentRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> seedPatient() async {
    final String id = uuid.v4();
    final DateTime now = DateTime.now();
    await db
        .into(db.patients)
        .insert(
          PatientsCompanion.insert(
            id: id,
            firstName: 'Amine',
            lastName: 'Trabelsi',
            dateOfBirth: DateTime(1990),
            phone: '20123456',
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<String> seedInvoice({
    required String patientId,
    required double totalAmount,
    String status = 'unpaid',
  }) async {
    final String invoiceId = uuid.v4();
    final DateTime now = DateTime.now();
    await db
        .into(db.invoices)
        .insert(
          InvoicesCompanion.insert(
            id: invoiceId,
            patientId: patientId,
            visitId: uuid.v4(),
            totalAmount: totalAmount,
            status: Value(status),
            createdByUserId: 'dentist-1',
            createdAt: now,
            updatedAt: now,
          ),
        );
    return invoiceId;
  }

  group('PaymentRepositoryImpl.recordPayment', () {
    test('a partial payment sets the Invoice to partially_paid, and the '
        'status is always derived from the sum of Payments, never directly '
        'writable', () async {
      final String patientId = await seedPatient();
      final String invoiceId = await seedInvoice(
        patientId: patientId,
        totalAmount: 100,
      );

      await repository.recordPayment(
        role: Role.assistant,
        actorUserId: 'assistant-1',
        invoiceId: invoiceId,
        amount: 40,
      );

      final Invoice invoice = await (db.select(
        db.invoices,
      )..where((t) => t.id.equals(invoiceId))).getSingle();
      final List<PaymentRow> payments = await (db.select(
        db.payments,
      )..where((t) => t.invoiceId.equals(invoiceId))).get();
      final double totalPaid = payments.fold(
        0,
        (double sum, PaymentRow p) => sum + p.amount,
      );

      expect(totalPaid, 40);
      expect(
        invoice.status,
        totalPaid >= invoice.totalAmount
            ? InvoiceStatus.paid.name
            : InvoiceStatus.partiallyPaid.name,
      );
      expect(invoice.status, InvoiceStatus.partiallyPaid.name);
    });

    test('a full payment sets the Invoice to paid', () async {
      final String patientId = await seedPatient();
      final String invoiceId = await seedInvoice(
        patientId: patientId,
        totalAmount: 100,
      );

      await repository.recordPayment(
        role: Role.assistant,
        actorUserId: 'assistant-1',
        invoiceId: invoiceId,
        amount: 100,
      );

      final Invoice invoice = await (db.select(
        db.invoices,
      )..where((t) => t.id.equals(invoiceId))).getSingle();
      expect(invoice.status, InvoiceStatus.paid.name);
    });

    test('multiple payments accumulate towards paid', () async {
      final String patientId = await seedPatient();
      final String invoiceId = await seedInvoice(
        patientId: patientId,
        totalAmount: 100,
      );

      await repository.recordPayment(
        role: Role.assistant,
        actorUserId: 'assistant-1',
        invoiceId: invoiceId,
        amount: 40,
      );
      final Invoice afterFirst = await (db.select(
        db.invoices,
      )..where((t) => t.id.equals(invoiceId))).getSingle();
      expect(afterFirst.status, InvoiceStatus.partiallyPaid.name);

      await repository.recordPayment(
        role: Role.assistant,
        actorUserId: 'assistant-1',
        invoiceId: invoiceId,
        amount: 60,
      );
      final Invoice afterSecond = await (db.select(
        db.invoices,
      )..where((t) => t.id.equals(invoiceId))).getSingle();
      expect(afterSecond.status, InvoiceStatus.paid.name);

      final List<PaymentRow> payments = await (db.select(
        db.payments,
      )..where((t) => t.invoiceId.equals(invoiceId))).get();
      expect(payments.length, 2);
    });

    test('an overpayment still sets the Invoice to paid', () async {
      final String patientId = await seedPatient();
      final String invoiceId = await seedInvoice(
        patientId: patientId,
        totalAmount: 100,
      );

      await repository.recordPayment(
        role: Role.assistant,
        actorUserId: 'assistant-1',
        invoiceId: invoiceId,
        amount: 150,
      );

      final Invoice invoice = await (db.select(
        db.invoices,
      )..where((t) => t.id.equals(invoiceId))).getSingle();
      expect(invoice.status, InvoiceStatus.paid.name);
    });

    test(
      'recording a payment on a draft Invoice auto-finalizes it first',
      () async {
        final String patientId = await seedPatient();
        final String invoiceId = await seedInvoice(
          patientId: patientId,
          totalAmount: 100,
          status: 'draft',
        );

        await repository.recordPayment(
          role: Role.assistant,
          actorUserId: 'assistant-1',
          invoiceId: invoiceId,
          amount: 40,
        );

        final Invoice invoice = await (db.select(
          db.invoices,
        )..where((t) => t.id.equals(invoiceId))).getSingle();
        expect(invoice.status, InvoiceStatus.partiallyPaid.name);

        final List<InvoiceFinalization> finalizations = await (db.select(
          db.invoiceFinalizations,
        )..where((t) => t.invoiceId.equals(invoiceId))).get();
        expect(finalizations.length, 1);
        expect(finalizations.single.actorUserId, 'assistant-1');
      },
    );

    test('saves the recorded_by_user_id, method, date, and notes', () async {
      final String patientId = await seedPatient();
      final String invoiceId = await seedInvoice(
        patientId: patientId,
        totalAmount: 100,
      );
      final DateTime paymentDate = DateTime(2026, 1, 15);

      final String paymentId = await repository.recordPayment(
        role: Role.assistant,
        actorUserId: 'assistant-1',
        invoiceId: invoiceId,
        amount: 40,
        method: PaymentMethod.card,
        paymentDate: paymentDate,
        notes: 'Paid via terminal',
      );

      final PaymentRow payment = await (db.select(
        db.payments,
      )..where((t) => t.id.equals(paymentId))).getSingle();
      expect(payment.recordedByUserId, 'assistant-1');
      expect(payment.method, 'card');
      expect(payment.paymentDate.toUtc(), paymentDate.toUtc());
      expect(payment.notes, 'Paid via terminal');
    });

    test('defaults to cash and today when method/date are omitted', () async {
      final String patientId = await seedPatient();
      final String invoiceId = await seedInvoice(
        patientId: patientId,
        totalAmount: 100,
      );

      final String paymentId = await repository.recordPayment(
        role: Role.assistant,
        actorUserId: 'assistant-1',
        invoiceId: invoiceId,
        amount: 40,
      );

      final PaymentRow payment = await (db.select(
        db.payments,
      )..where((t) => t.id.equals(paymentId))).getSingle();
      expect(payment.method, 'cash');
      expect(payment.notes, isNull);
      expect(payment.paymentDate, isNotNull);
    });

    test(
      'throws PaymentInvoiceVoidedException when the Invoice is voided',
      () async {
        final String patientId = await seedPatient();
        final String invoiceId = await seedInvoice(
          patientId: patientId,
          totalAmount: 100,
          status: 'voided',
        );

        expect(
          () => repository.recordPayment(
            role: Role.assistant,
            actorUserId: 'assistant-1',
            invoiceId: invoiceId,
            amount: 40,
          ),
          throwsA(isA<PaymentInvoiceVoidedException>()),
        );

        final List<PaymentRow> payments = await db.select(db.payments).get();
        expect(payments, isEmpty);
      },
    );

    test(
      'throws PaymentValidationException for a non-positive amount',
      () async {
        final String patientId = await seedPatient();
        final String invoiceId = await seedInvoice(
          patientId: patientId,
          totalAmount: 100,
        );

        expect(
          () => repository.recordPayment(
            role: Role.assistant,
            actorUserId: 'assistant-1',
            invoiceId: invoiceId,
            amount: 0,
          ),
          throwsA(isA<PaymentValidationException>()),
        );
      },
    );

    test('rejects a Nurse with PermissionDeniedException', () async {
      final String patientId = await seedPatient();
      final String invoiceId = await seedInvoice(
        patientId: patientId,
        totalAmount: 100,
      );

      expect(
        () => repository.recordPayment(
          role: Role.nurse,
          actorUserId: 'nurse-1',
          invoiceId: invoiceId,
          amount: 40,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });
  });
}
