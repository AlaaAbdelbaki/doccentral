import 'package:docentral/features/day_closeout/data/day_closeout_repository_impl.dart';
import 'package:docentral/features/day_closeout/domain/day_closeout_summary.dart';
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
  late DayCloseoutRepositoryImpl repository;
  const Uuid uuid = Uuid();
  final DateTime today = DateTime(2026, 6, 8);
  final DateTime yesterday = today.subtract(const Duration(days: 1));

  setUp(() {
    db = _createInMemoryDatabase();
    repository = DayCloseoutRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> seedVisit({
    required DateTime endedAt,
    String status = 'completed',
  }) async {
    final String appointmentId = uuid.v4();
    final String visitId = uuid.v4();
    await db
        .into(db.appointments)
        .insert(
          AppointmentsCompanion.insert(
            id: appointmentId,
            patientId: 'patient-1',
            assignedUserId: 'dentist-1',
            startTime: endedAt,
            endTime: endedAt.add(const Duration(minutes: 30)),
            createdAt: endedAt,
            updatedAt: endedAt,
          ),
        );
    await db
        .into(db.visits)
        .insert(
          VisitsCompanion.insert(
            id: visitId,
            appointmentId: appointmentId,
            patientId: 'patient-1',
            dentistId: 'dentist-1',
            status: Value(status),
            startedAt: endedAt,
            endedAt: Value(endedAt),
            createdAt: endedAt,
            updatedAt: endedAt,
          ),
        );
    return visitId;
  }

  Future<String> seedInvoice({
    required DateTime createdAt,
    required double totalAmount,
    String status = 'unpaid',
  }) async {
    final String id = uuid.v4();
    await db
        .into(db.invoices)
        .insert(
          InvoicesCompanion.insert(
            id: id,
            patientId: 'patient-1',
            visitId: 'visit-1',
            totalAmount: totalAmount,
            status: Value(status),
            createdByUserId: 'actor-1',
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
    return id;
  }

  Future<String> seedPayment({
    required DateTime paymentDate,
    required double amount,
    String method = 'cash',
  }) async {
    final String id = uuid.v4();
    await db
        .into(db.payments)
        .insert(
          PaymentsCompanion.insert(
            id: id,
            invoiceId: 'invoice-1',
            amount: amount,
            method: Value(method),
            paymentDate: paymentDate,
            recordedByUserId: 'actor-1',
            createdAt: paymentDate,
            updatedAt: paymentDate,
          ),
        );
    return id;
  }

  group('DayCloseoutRepositoryImpl.watchSummary', () {
    test(
      'counts only completed Visits, Payments, and Invoices for the given day',
      () async {
        await seedVisit(endedAt: today.add(const Duration(hours: 9)));
        await seedVisit(endedAt: today.add(const Duration(hours: 11)));
        await seedVisit(
          endedAt: yesterday.add(const Duration(hours: 9)),
        ); // different day, excluded
        await seedVisit(
          endedAt: today.add(const Duration(hours: 10)),
          status: 'inProgress',
        ); // not completed, excluded

        await seedPayment(
          paymentDate: today.add(const Duration(hours: 9)),
          amount: 50,
        );
        await seedPayment(
          paymentDate: today.add(const Duration(hours: 10)),
          amount: 30,
          method: 'card',
        );
        await seedPayment(
          paymentDate: yesterday.add(const Duration(hours: 9)),
          amount: 999,
        ); // different day, excluded

        await seedInvoice(
          createdAt: today.add(const Duration(hours: 9)),
          totalAmount: 100,
        );
        await seedInvoice(
          createdAt: yesterday.add(const Duration(hours: 9)),
          totalAmount: 999,
        ); // different day, excluded

        final DayCloseoutSummary summary = await repository
            .watchSummary(role: Role.assistant, day: today)
            .first;

        expect(summary.completedVisitsCount, 2);
        expect(summary.paymentTotalsByMethod[PaymentMethod.cash], 50);
        expect(summary.paymentTotalsByMethod[PaymentMethod.card], 30);
        expect(summary.totalPayments, 80);
        expect(summary.newInvoicesTotal, 100);
        expect(summary.outstandingInvoicesCount, 1);
      },
    );

    test(
      'counts unpaid and partially_paid Invoices as outstanding, not paid or voided',
      () async {
        await seedInvoice(
          createdAt: today.add(const Duration(hours: 9)),
          totalAmount: 100,
        );
        await seedInvoice(
          createdAt: today.add(const Duration(hours: 9)),
          totalAmount: 100,
          status: 'partiallyPaid',
        );
        await seedInvoice(
          createdAt: today.add(const Duration(hours: 9)),
          totalAmount: 100,
          status: 'paid',
        );
        await seedInvoice(
          createdAt: today.add(const Duration(hours: 9)),
          totalAmount: 100,
          status: 'voided',
        );

        final DayCloseoutSummary summary = await repository
            .watchSummary(role: Role.assistant, day: today)
            .first;

        expect(summary.outstandingInvoicesCount, 2);
      },
    );

    test('emits an updated summary when a new Payment is recorded', () async {
      final Stream<DayCloseoutSummary> stream = repository.watchSummary(
        role: Role.assistant,
        day: today,
      );
      final List<DayCloseoutSummary> emissions = <DayCloseoutSummary>[];
      final subscription = stream.listen(emissions.add);
      addTearDown(subscription.cancel);

      await Future<void>.delayed(Duration.zero);
      expect(emissions.last.totalPayments, 0);

      await seedPayment(
        paymentDate: today.add(const Duration(hours: 9)),
        amount: 75,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emissions.last.totalPayments, 75);
    });

    test(
      'empty day summary has zero totals and an empty payments map',
      () async {
        final DayCloseoutSummary summary = await repository
            .watchSummary(role: Role.assistant, day: today)
            .first;

        expect(summary.completedVisitsCount, 0);
        expect(summary.paymentTotalsByMethod, isEmpty);
        expect(summary.newInvoicesTotal, 0);
        expect(summary.outstandingInvoicesCount, 0);
      },
    );

    test(
      'throws PermissionDeniedException for a role without canViewDayCloseout',
      () {
        expect(
          () => repository.watchSummary(role: Role.nurse, day: today),
          throwsA(isA<PermissionDeniedException>()),
        );
      },
    );
  });
}
