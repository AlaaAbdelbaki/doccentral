import 'package:docentral/features/invoice/domain/invoice_status.dart';
import 'package:docentral/features/invoice/domain/payment.dart';
import 'package:docentral/features/invoice/domain/payment_exceptions.dart';
import 'package:docentral/features/invoice/domain/payment_method.dart';
import 'package:docentral/features/invoice/domain/payment_repository.dart';
import 'package:docentral/shared/data/database/app_database.dart';
import 'package:docentral/shared/data/database/tables/invoices_table.dart';
import 'package:docentral/shared/data/database/tables/payments_table.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/permission_guard.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl(this._db, {Uuid uuid = const Uuid()}) : _uuid = uuid;

  final AppDatabase _db;
  final Uuid _uuid;

  Payment _toRecord(PaymentRow row) {
    return Payment(
      id: row.id,
      invoiceId: row.invoiceId,
      amount: row.amount,
      method: PaymentMethod.values.byName(row.method),
      paymentDate: row.paymentDate,
      recordedByUserId: row.recordedByUserId,
      notes: row.notes,
    );
  }

  @override
  Stream<List<Payment>> watchPaymentsForInvoice({
    required Role role,
    required String invoiceId,
  }) {
    requirePermission(role, Permission.canRecordPayment);

    final SimpleSelectStatement<$PaymentsTable, PaymentRow> select =
        _db.select(_db.payments)
          ..where((Payments t) => t.invoiceId.equals(invoiceId))
          ..orderBy([(Payments t) => OrderingTerm.asc(t.paymentDate)]);

    return select.watch().map(
      (List<PaymentRow> rows) => rows.map(_toRecord).toList(growable: false),
    );
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
    requirePermission(role, Permission.canRecordPayment);

    if (amount <= 0) {
      throw const PaymentValidationException(
        'Payment amount must be a positive number.',
      );
    }

    return _db.transaction(() async {
      final Invoice invoice = await (_db.select(
        _db.invoices,
      )..where((Invoices t) => t.id.equals(invoiceId))).getSingle();

      if (invoice.status == InvoiceStatus.voided.name) {
        throw const PaymentInvoiceVoidedException();
      }

      final DateTime now = DateTime.now().toUtc();

      if (invoice.status == InvoiceStatus.draft.name) {
        await (_db.update(
          _db.invoices,
        )..where((Invoices t) => t.id.equals(invoiceId))).write(
          InvoicesCompanion(
            status: Value(InvoiceStatus.unpaid.name),
            updatedAt: Value(now),
          ),
        );
        await _db
            .into(_db.invoiceFinalizations)
            .insert(
              InvoiceFinalizationsCompanion.insert(
                id: _uuid.v4(),
                invoiceId: invoiceId,
                actorUserId: actorUserId,
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      final String paymentId = _uuid.v4();
      await _db
          .into(_db.payments)
          .insert(
            PaymentsCompanion.insert(
              id: paymentId,
              invoiceId: invoiceId,
              amount: amount,
              method: Value(method.name),
              paymentDate: paymentDate?.toUtc() ?? now,
              notes: Value(notes?.trim()),
              recordedByUserId: actorUserId,
              createdAt: now,
              updatedAt: now,
            ),
          );

      final List<PaymentRow> payments = await (_db.select(
        _db.payments,
      )..where((Payments t) => t.invoiceId.equals(invoiceId))).get();
      final double totalPaid = payments.fold(
        0,
        (double sum, PaymentRow p) => sum + p.amount,
      );

      final String derivedStatus = totalPaid >= invoice.totalAmount
          ? InvoiceStatus.paid.name
          : InvoiceStatus.partiallyPaid.name;

      await (_db.update(
        _db.invoices,
      )..where((Invoices t) => t.id.equals(invoiceId))).write(
        InvoicesCompanion(status: Value(derivedStatus), updatedAt: Value(now)),
      );

      return paymentId;
    });
  }
}
