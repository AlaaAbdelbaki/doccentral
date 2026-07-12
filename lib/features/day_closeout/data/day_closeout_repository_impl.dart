import 'dart:async';

import 'package:docentral/features/day_closeout/domain/day_closeout_exceptions.dart';
import 'package:docentral/features/day_closeout/domain/day_closeout_record.dart';
import 'package:docentral/features/day_closeout/domain/day_closeout_repository.dart';
import 'package:docentral/features/day_closeout/domain/day_closeout_summary.dart';
import 'package:docentral/features/invoice/domain/invoice_status.dart';
import 'package:docentral/features/invoice/domain/payment_method.dart';
import 'package:docentral/features/visit/domain/visit_status.dart';
import 'package:docentral/shared/data/database/app_database.dart';
import 'package:docentral/shared/data/database/tables/day_closeouts_table.dart';
import 'package:docentral/shared/data/database/tables/invoices_table.dart';
import 'package:docentral/shared/data/database/tables/payments_table.dart';
import 'package:docentral/shared/data/database/tables/visits_table.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/permission_guard.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class DayCloseoutRepositoryImpl implements DayCloseoutRepository {
  DayCloseoutRepositoryImpl(this._db, {Uuid uuid = const Uuid()})
    : _uuid = uuid;

  final AppDatabase _db;
  final Uuid _uuid;

  @override
  Stream<DayCloseoutSummary> watchSummary({
    required Role role,
    required DateTime day,
  }) {
    requirePermission(role, Permission.canViewDayCloseout);

    final DateTime dayStart = DateTime(day.year, day.month, day.day);
    final DateTime dayEnd = dayStart.add(const Duration(days: 1));

    return _combineLatest4(
      _watchCompletedVisitsCount(dayStart, dayEnd),
      _watchPaymentTotalsByMethod(dayStart, dayEnd),
      _watchNewInvoicesTotal(dayStart, dayEnd),
      _watchOutstandingInvoicesCount(dayStart, dayEnd),
      (
        int visits,
        Map<PaymentMethod, double> payments,
        double invoiceTotal,
        int outstanding,
      ) => DayCloseoutSummary(
        completedVisitsCount: visits,
        paymentTotalsByMethod: payments,
        newInvoicesTotal: invoiceTotal,
        outstandingInvoicesCount: outstanding,
      ),
    );
  }

  @override
  Future<String> confirmCloseout({
    required Role role,
    required String actorUserId,
    required DateTime day,
    required double countedCash,
  }) async {
    requirePermission(role, Permission.canConfirmDayCloseout);

    final DateTime closeoutDate = DateTime(day.year, day.month, day.day);

    return _db.transaction(() async {
      final DayCloseout? existing =
          await (_db.select(
                _db.dayCloseouts,
              )..where((DayCloseouts t) => t.closeoutDate.equals(closeoutDate)))
              .getSingleOrNull();
      if (existing != null) {
        throw const DayCloseoutAlreadyExistsException();
      }

      final double expectedCash = await _computeExpectedCash(
        closeoutDate,
        closeoutDate.add(const Duration(days: 1)),
      );

      final String id = _uuid.v4();
      final DateTime now = DateTime.now().toUtc();
      await _db
          .into(_db.dayCloseouts)
          .insert(
            DayCloseoutsCompanion.insert(
              id: id,
              closeoutDate: closeoutDate,
              expectedCash: expectedCash,
              countedCash: countedCash,
              delta: expectedCash - countedCash,
              actorUserId: actorUserId,
              createdAt: now,
              updatedAt: now,
            ),
          );
      return id;
    });
  }

  Future<double> _computeExpectedCash(DateTime start, DateTime end) async {
    final SimpleSelectStatement<$PaymentsTable, PaymentRow> select =
        _db.select(_db.payments)..where(
          (Payments t) =>
              t.deletedAt.isNull() &
              t.method.equals(PaymentMethod.cash.name) &
              t.paymentDate.isBiggerOrEqualValue(start) &
              t.paymentDate.isSmallerThanValue(end),
        );
    final List<PaymentRow> rows = await select.get();
    return rows.fold<double>(0, (double sum, PaymentRow r) => sum + r.amount);
  }

  @override
  Stream<DayCloseoutRecord?> watchCloseoutForDay({
    required Role role,
    required DateTime day,
  }) {
    requirePermission(role, Permission.canViewDayCloseout);

    final DateTime closeoutDate = DateTime(day.year, day.month, day.day);
    final SimpleSelectStatement<$DayCloseoutsTable, DayCloseout> select =
        _db.select(_db.dayCloseouts)
          ..where((DayCloseouts t) => t.closeoutDate.equals(closeoutDate));

    return select.watchSingleOrNull().map(
      (DayCloseout? row) => row == null
          ? null
          : DayCloseoutRecord(
              id: row.id,
              closeoutDate: row.closeoutDate,
              expectedCash: row.expectedCash,
              countedCash: row.countedCash,
              delta: row.delta,
              actorUserId: row.actorUserId,
              recordedAt: row.createdAt,
            ),
    );
  }

  Stream<int> _watchCompletedVisitsCount(DateTime start, DateTime end) {
    final SimpleSelectStatement<$VisitsTable, Visit> query =
        _db.select(_db.visits)..where(
          (Visits t) =>
              t.deletedAt.isNull() &
              t.status.equals(VisitStatus.completed.name) &
              t.endedAt.isBiggerOrEqualValue(start) &
              t.endedAt.isSmallerThanValue(end),
        );
    return query.watch().map((List<Visit> rows) => rows.length);
  }

  Stream<Map<PaymentMethod, double>> _watchPaymentTotalsByMethod(
    DateTime start,
    DateTime end,
  ) {
    final SimpleSelectStatement<$PaymentsTable, PaymentRow> query =
        _db.select(_db.payments)..where(
          (Payments t) =>
              t.deletedAt.isNull() &
              t.paymentDate.isBiggerOrEqualValue(start) &
              t.paymentDate.isSmallerThanValue(end),
        );
    return query.watch().map((List<PaymentRow> rows) {
      final Map<PaymentMethod, double> totals = <PaymentMethod, double>{};
      for (final PaymentRow row in rows) {
        final PaymentMethod method = PaymentMethod.values.byName(row.method);
        totals[method] = (totals[method] ?? 0) + row.amount;
      }
      return totals;
    });
  }

  Stream<double> _watchNewInvoicesTotal(DateTime start, DateTime end) {
    final SimpleSelectStatement<$InvoicesTable, Invoice> query =
        _db.select(_db.invoices)..where(
          (Invoices t) =>
              t.deletedAt.isNull() &
              t.createdAt.isBiggerOrEqualValue(start) &
              t.createdAt.isSmallerThanValue(end),
        );
    return query.watch().map(
      (List<Invoice> rows) =>
          rows.fold<double>(0, (double sum, Invoice r) => sum + r.totalAmount),
    );
  }

  Stream<int> _watchOutstandingInvoicesCount(DateTime start, DateTime end) {
    final SimpleSelectStatement<$InvoicesTable, Invoice> query =
        _db.select(_db.invoices)..where(
          (Invoices t) =>
              t.deletedAt.isNull() &
              t.createdAt.isBiggerOrEqualValue(start) &
              t.createdAt.isSmallerThanValue(end) &
              (t.status.equals(InvoiceStatus.unpaid.name) |
                  t.status.equals(InvoiceStatus.partiallyPaid.name)),
        );
    return query.watch().map((List<Invoice> rows) => rows.length);
  }
}

/// Combines the latest values of four streams into one, emitting whenever
/// any source emits, once all four have produced at least one value.
Stream<R> _combineLatest4<A, B, C, D, R>(
  Stream<A> streamA,
  Stream<B> streamB,
  Stream<C> streamC,
  Stream<D> streamD,
  R Function(A a, B b, C c, D d) combine,
) {
  late final StreamController<R> controller;
  StreamSubscription<A>? subA;
  StreamSubscription<B>? subB;
  StreamSubscription<C>? subC;
  StreamSubscription<D>? subD;

  A? latestA;
  B? latestB;
  C? latestC;
  D? latestD;
  bool hasA = false, hasB = false, hasC = false, hasD = false;

  void emitIfReady() {
    if (hasA && hasB && hasC && hasD) {
      controller.add(
        combine(latestA as A, latestB as B, latestC as C, latestD as D),
      );
    }
  }

  controller = StreamController<R>.broadcast(
    onListen: () {
      subA = streamA.listen((A value) {
        latestA = value;
        hasA = true;
        emitIfReady();
      });
      subB = streamB.listen((B value) {
        latestB = value;
        hasB = true;
        emitIfReady();
      });
      subC = streamC.listen((C value) {
        latestC = value;
        hasC = true;
        emitIfReady();
      });
      subD = streamD.listen((D value) {
        latestD = value;
        hasD = true;
        emitIfReady();
      });
    },
    onCancel: () async {
      await subA?.cancel();
      await subB?.cancel();
      await subC?.cancel();
      await subD?.cancel();
    },
  );

  return controller.stream;
}
