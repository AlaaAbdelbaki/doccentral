import 'package:docentral/features/invoice/data/invoice_repository_impl.dart';
import 'package:docentral/features/invoice/domain/invoice_adjustment_type.dart';
import 'package:docentral/features/invoice/domain/invoice_exceptions.dart';
import 'package:docentral/features/invoice/domain/invoice_record.dart';
import 'package:docentral/features/invoice/domain/invoice_status.dart';
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
  late InvoiceRepositoryImpl repository;
  const Uuid uuid = Uuid();

  setUp(() {
    db = _createInMemoryDatabase();
    repository = InvoiceRepositoryImpl(db);
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

  Future<({String invoiceId, String visitId})> seedInvoice({
    required String patientId,
    List<(String description, double unitPrice, int quantity)> treatmentItems =
        const <(String, double, int)>[],
    String status = 'draft',
  }) async {
    final String visitId = uuid.v4();
    final String invoiceId = uuid.v4();
    final DateTime now = DateTime.now();

    final double total = treatmentItems.fold(
      0,
      (double sum, (String, double, int) item) => sum + item.$2 * item.$3,
    );

    await db
        .into(db.invoices)
        .insert(
          InvoicesCompanion.insert(
            id: invoiceId,
            patientId: patientId,
            visitId: visitId,
            totalAmount: total,
            status: Value(status),
            createdByUserId: 'dentist-1',
            createdAt: now,
            updatedAt: now,
          ),
        );

    for (final (String description, double unitPrice, int quantity)
        in treatmentItems) {
      await db
          .into(db.invoiceItems)
          .insert(
            InvoiceItemsCompanion.insert(
              id: uuid.v4(),
              invoiceId: invoiceId,
              description: description,
              quantity: quantity,
              unitPrice: unitPrice,
              totalPrice: unitPrice * quantity,
              createdAt: now,
              updatedAt: now,
            ),
          );
    }

    return (invoiceId: invoiceId, visitId: visitId);
  }

  group('InvoiceRepositoryImpl.watchInvoiceForVisit', () {
    test('returns the Invoice linked to the visit', () async {
      final String patientId = await seedPatient();
      final ({String invoiceId, String visitId}) seeded = await seedInvoice(
        patientId: patientId,
        treatmentItems: <(String, double, int)>[('Filling', 50, 2)],
      );

      final InvoiceRecord? invoice = await repository
          .watchInvoiceForVisit(role: Role.assistant, visitId: seeded.visitId)
          .first;

      expect(invoice?.id, seeded.invoiceId);
      expect(invoice?.totalAmount, 100);
      expect(invoice?.status, InvoiceStatus.draft);
    });
  });

  group('InvoiceRepositoryImpl.addAdjustment', () {
    test('a discount reduces the total and total is always the sum of Items, '
        'never a directly-writable value', () async {
      final String patientId = await seedPatient();
      final ({String invoiceId, String visitId}) seeded = await seedInvoice(
        patientId: patientId,
        treatmentItems: <(String, double, int)>[('Filling', 50, 2)],
      );

      await repository.addAdjustment(
        role: Role.assistant,
        invoiceId: seeded.invoiceId,
        adjustmentType: InvoiceAdjustmentType.discount,
        description: 'Loyalty discount',
        amount: 20,
      );

      final Invoice invoice = await (db.select(
        db.invoices,
      )..where((t) => t.id.equals(seeded.invoiceId))).getSingle();
      final List<InvoiceItemRow> items = await (db.select(
        db.invoiceItems,
      )..where((t) => t.invoiceId.equals(seeded.invoiceId))).get();

      final double expectedTotal = items.fold(
        0,
        (double sum, InvoiceItemRow item) => sum + item.totalPrice,
      );
      expect(invoice.totalAmount, expectedTotal);
      expect(invoice.totalAmount, 80);
      expect(items.length, 2);

      final InvoiceItemRow adjustment = items.firstWhere(
        (InvoiceItemRow i) => i.adjustmentType != null,
      );
      expect(adjustment.adjustmentType, 'discount');
      expect(adjustment.totalPrice, -20);
      expect(adjustment.unitPrice, 20);
    });

    test('a surcharge increases the total', () async {
      final String patientId = await seedPatient();
      final ({String invoiceId, String visitId}) seeded = await seedInvoice(
        patientId: patientId,
        treatmentItems: <(String, double, int)>[('Filling', 50, 2)],
      );

      await repository.addAdjustment(
        role: Role.assistant,
        invoiceId: seeded.invoiceId,
        adjustmentType: InvoiceAdjustmentType.surcharge,
        description: 'After-hours surcharge',
        amount: 15,
      );

      final Invoice invoice = await (db.select(
        db.invoices,
      )..where((t) => t.id.equals(seeded.invoiceId))).getSingle();
      expect(invoice.totalAmount, 115);
    });

    test(
      'multiple adjustments stack into a running, recomputed total',
      () async {
        final String patientId = await seedPatient();
        final ({String invoiceId, String visitId}) seeded = await seedInvoice(
          patientId: patientId,
          treatmentItems: <(String, double, int)>[('Filling', 50, 2)],
        );

        await repository.addAdjustment(
          role: Role.assistant,
          invoiceId: seeded.invoiceId,
          adjustmentType: InvoiceAdjustmentType.discount,
          description: 'Loyalty discount',
          amount: 20,
        );
        await repository.addAdjustment(
          role: Role.assistant,
          invoiceId: seeded.invoiceId,
          adjustmentType: InvoiceAdjustmentType.surcharge,
          description: 'After-hours surcharge',
          amount: 15,
        );

        final Invoice invoice = await (db.select(
          db.invoices,
        )..where((t) => t.id.equals(seeded.invoiceId))).getSingle();
        final List<InvoiceItemRow> items = await (db.select(
          db.invoiceItems,
        )..where((t) => t.invoiceId.equals(seeded.invoiceId))).get();
        final double expectedTotal = items.fold(
          0,
          (double sum, InvoiceItemRow item) => sum + item.totalPrice,
        );

        expect(invoice.totalAmount, expectedTotal);
        expect(invoice.totalAmount, 95);
        expect(items.length, 3);
      },
    );

    test(
      'throws InvoiceNotDraftException when the invoice is not draft',
      () async {
        final String patientId = await seedPatient();
        final ({String invoiceId, String visitId}) seeded = await seedInvoice(
          patientId: patientId,
          treatmentItems: <(String, double, int)>[('Filling', 50, 1)],
          status: 'unpaid',
        );

        expect(
          () => repository.addAdjustment(
            role: Role.assistant,
            invoiceId: seeded.invoiceId,
            adjustmentType: InvoiceAdjustmentType.discount,
            description: 'Too late',
            amount: 10,
          ),
          throwsA(isA<InvoiceNotDraftException>()),
        );

        final Invoice invoice = await (db.select(
          db.invoices,
        )..where((t) => t.id.equals(seeded.invoiceId))).getSingle();
        expect(invoice.totalAmount, 50);
        final List<InvoiceItemRow> items = await (db.select(
          db.invoiceItems,
        )..where((t) => t.invoiceId.equals(seeded.invoiceId))).get();
        expect(items.length, 1);
      },
    );

    test(
      'throws InvoiceAdjustmentValidationException for a zero amount',
      () async {
        final String patientId = await seedPatient();
        final ({String invoiceId, String visitId}) seeded = await seedInvoice(
          patientId: patientId,
          treatmentItems: <(String, double, int)>[('Filling', 50, 1)],
        );

        expect(
          () => repository.addAdjustment(
            role: Role.assistant,
            invoiceId: seeded.invoiceId,
            adjustmentType: InvoiceAdjustmentType.discount,
            description: 'Invalid',
            amount: 0,
          ),
          throwsA(isA<InvoiceAdjustmentValidationException>()),
        );
      },
    );

    test(
      'throws InvoiceAdjustmentValidationException for a negative amount',
      () async {
        final String patientId = await seedPatient();
        final ({String invoiceId, String visitId}) seeded = await seedInvoice(
          patientId: patientId,
          treatmentItems: <(String, double, int)>[('Filling', 50, 1)],
        );

        expect(
          () => repository.addAdjustment(
            role: Role.assistant,
            invoiceId: seeded.invoiceId,
            adjustmentType: InvoiceAdjustmentType.surcharge,
            description: 'Invalid',
            amount: -5,
          ),
          throwsA(isA<InvoiceAdjustmentValidationException>()),
        );
      },
    );

    test('rejects a Nurse with PermissionDeniedException', () async {
      final String patientId = await seedPatient();
      final ({String invoiceId, String visitId}) seeded = await seedInvoice(
        patientId: patientId,
        treatmentItems: <(String, double, int)>[('Filling', 50, 1)],
      );

      expect(
        () => repository.addAdjustment(
          role: Role.nurse,
          invoiceId: seeded.invoiceId,
          adjustmentType: InvoiceAdjustmentType.discount,
          description: 'Not allowed',
          amount: 5,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });
  });

  group('InvoiceRepositoryImpl.finalizeInvoice', () {
    test(
      'transitions a draft Invoice to unpaid and logs the actor/timestamp',
      () async {
        final String patientId = await seedPatient();
        final ({String invoiceId, String visitId}) seeded = await seedInvoice(
          patientId: patientId,
          treatmentItems: <(String, double, int)>[('Filling', 50, 2)],
        );

        await repository.finalizeInvoice(
          role: Role.assistant,
          actorUserId: 'assistant-1',
          invoiceId: seeded.invoiceId,
        );

        final Invoice invoice = await (db.select(
          db.invoices,
        )..where((t) => t.id.equals(seeded.invoiceId))).getSingle();
        expect(invoice.status, InvoiceStatus.unpaid.name);

        final List<InvoiceFinalization> logs = await (db.select(
          db.invoiceFinalizations,
        )..where((t) => t.invoiceId.equals(seeded.invoiceId))).get();
        expect(logs.length, 1);
        expect(logs.single.actorUserId, 'assistant-1');
      },
    );

    test(
      'throws InvoiceNotDraftException when the invoice is not draft',
      () async {
        final String patientId = await seedPatient();
        final ({String invoiceId, String visitId}) seeded = await seedInvoice(
          patientId: patientId,
          treatmentItems: <(String, double, int)>[('Filling', 50, 1)],
          status: 'unpaid',
        );

        expect(
          () => repository.finalizeInvoice(
            role: Role.assistant,
            actorUserId: 'assistant-1',
            invoiceId: seeded.invoiceId,
          ),
          throwsA(isA<InvoiceNotDraftException>()),
        );

        final List<InvoiceFinalization> logs = await db
            .select(db.invoiceFinalizations)
            .get();
        expect(logs, isEmpty);
      },
    );

    test('rejects a Nurse with PermissionDeniedException', () async {
      final String patientId = await seedPatient();
      final ({String invoiceId, String visitId}) seeded = await seedInvoice(
        patientId: patientId,
        treatmentItems: <(String, double, int)>[('Filling', 50, 1)],
      );

      expect(
        () => repository.finalizeInvoice(
          role: Role.nurse,
          actorUserId: 'nurse-1',
          invoiceId: seeded.invoiceId,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });
  });

  group('InvoiceRepositoryImpl.voidInvoice', () {
    test('transitions any non-voided Invoice to voided and logs the '
        'actor/reason/timestamp', () async {
      final String patientId = await seedPatient();
      final ({String invoiceId, String visitId}) seeded = await seedInvoice(
        patientId: patientId,
        treatmentItems: <(String, double, int)>[('Filling', 50, 2)],
        status: 'paid',
      );

      await repository.voidInvoice(
        role: Role.doctor,
        actorUserId: 'dentist-1',
        invoiceId: seeded.invoiceId,
        reason: 'Billed to the wrong patient',
      );

      final Invoice invoice = await (db.select(
        db.invoices,
      )..where((t) => t.id.equals(seeded.invoiceId))).getSingle();
      expect(invoice.status, InvoiceStatus.voided.name);

      final List<InvoiceVoid> logs = await (db.select(
        db.invoiceVoids,
      )..where((t) => t.invoiceId.equals(seeded.invoiceId))).get();
      expect(logs.length, 1);
      expect(logs.single.actorUserId, 'dentist-1');
      expect(logs.single.reason, 'Billed to the wrong patient');
    });

    test('preserves prior Invoice Items unchanged', () async {
      final String patientId = await seedPatient();
      final ({String invoiceId, String visitId}) seeded = await seedInvoice(
        patientId: patientId,
        treatmentItems: <(String, double, int)>[('Filling', 50, 2)],
        status: 'unpaid',
      );

      await repository.voidInvoice(
        role: Role.doctor,
        actorUserId: 'dentist-1',
        invoiceId: seeded.invoiceId,
        reason: 'Test reason',
      );

      final List<InvoiceItemRow> items = await (db.select(
        db.invoiceItems,
      )..where((t) => t.invoiceId.equals(seeded.invoiceId))).get();
      expect(items.length, 1);
      expect(items.single.description, 'Filling');
    });

    test('throws InvoiceAlreadyVoidedException when already voided', () async {
      final String patientId = await seedPatient();
      final ({String invoiceId, String visitId}) seeded = await seedInvoice(
        patientId: patientId,
        treatmentItems: <(String, double, int)>[('Filling', 50, 1)],
        status: 'voided',
      );

      expect(
        () => repository.voidInvoice(
          role: Role.doctor,
          actorUserId: 'dentist-1',
          invoiceId: seeded.invoiceId,
          reason: 'Test reason',
        ),
        throwsA(isA<InvoiceAlreadyVoidedException>()),
      );

      final List<InvoiceVoid> logs = await db.select(db.invoiceVoids).get();
      expect(logs, isEmpty);
    });

    test('rejects an Assistant with PermissionDeniedException', () async {
      final String patientId = await seedPatient();
      final ({String invoiceId, String visitId}) seeded = await seedInvoice(
        patientId: patientId,
        treatmentItems: <(String, double, int)>[('Filling', 50, 1)],
      );

      expect(
        () => repository.voidInvoice(
          role: Role.assistant,
          actorUserId: 'assistant-1',
          invoiceId: seeded.invoiceId,
          reason: 'Test reason',
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });
  });
}
