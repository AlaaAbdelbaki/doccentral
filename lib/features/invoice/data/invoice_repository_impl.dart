import 'package:docentral/features/invoice/domain/invoice_adjustment_type.dart';
import 'package:docentral/features/invoice/domain/invoice_exceptions.dart';
import 'package:docentral/features/invoice/domain/invoice_item.dart';
import 'package:docentral/features/invoice/domain/invoice_record.dart';
import 'package:docentral/features/invoice/domain/invoice_repository.dart';
import 'package:docentral/features/invoice/domain/invoice_status.dart';
import 'package:docentral/shared/data/database/app_database.dart';
import 'package:docentral/shared/data/database/tables/invoice_items_table.dart';
import 'package:docentral/shared/data/database/tables/invoices_table.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/permission_guard.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  InvoiceRepositoryImpl(this._db, {Uuid uuid = const Uuid()}) : _uuid = uuid;

  final AppDatabase _db;
  final Uuid _uuid;

  InvoiceRecord _toRecord(Invoice row) {
    return InvoiceRecord(
      id: row.id,
      patientId: row.patientId,
      visitId: row.visitId,
      totalAmount: row.totalAmount,
      status: InvoiceStatus.values.byName(row.status),
      createdByUserId: row.createdByUserId,
    );
  }

  @override
  Stream<InvoiceRecord?> watchInvoiceForVisit({
    required Role role,
    required String visitId,
  }) {
    requirePermission(role, Permission.canEditInvoice);

    final SimpleSelectStatement<$InvoicesTable, Invoice> select = _db.select(
      _db.invoices,
    )..where((Invoices t) => t.visitId.equals(visitId));

    return select.watchSingleOrNull().map(
      (Invoice? row) => row == null ? null : _toRecord(row),
    );
  }

  @override
  Stream<List<InvoiceItem>> watchItemsForInvoice({
    required Role role,
    required String invoiceId,
  }) {
    requirePermission(role, Permission.canEditInvoice);

    final SimpleSelectStatement<$InvoiceItemsTable, InvoiceItemRow> select =
        _db.select(_db.invoiceItems)
          ..where(
            (InvoiceItems t) =>
                t.invoiceId.equals(invoiceId) & t.deletedAt.isNull(),
          )
          ..orderBy([(InvoiceItems t) => OrderingTerm.asc(t.createdAt)]);

    return select.watch().map(
      (List<InvoiceItemRow> rows) =>
          rows.map(_rowToItem).toList(growable: false),
    );
  }

  InvoiceItem _rowToItem(InvoiceItemRow row) {
    return InvoiceItem(
      id: row.id,
      invoiceId: row.invoiceId,
      description: row.description,
      toothNumber: row.toothNumber,
      quantity: row.quantity,
      unitPrice: row.unitPrice,
      totalPrice: row.totalPrice,
      adjustmentType: row.adjustmentType == null
          ? null
          : InvoiceAdjustmentType.values.byName(row.adjustmentType!),
    );
  }

  @override
  Future<String> addAdjustment({
    required Role role,
    required String invoiceId,
    required InvoiceAdjustmentType adjustmentType,
    required String description,
    required double amount,
  }) async {
    requirePermission(role, Permission.canEditInvoice);

    if (amount <= 0) {
      throw const InvoiceAdjustmentValidationException(
        'Adjustment amount must be a positive number.',
      );
    }

    return _db.transaction(() async {
      final Invoice invoice = await (_db.select(
        _db.invoices,
      )..where((Invoices t) => t.id.equals(invoiceId))).getSingle();

      if (invoice.status != InvoiceStatus.draft.name) {
        throw const InvoiceNotDraftException();
      }

      final DateTime now = DateTime.now().toUtc();
      final String itemId = _uuid.v4();
      final double signedTotal =
          adjustmentType == InvoiceAdjustmentType.discount ? -amount : amount;

      await _db
          .into(_db.invoiceItems)
          .insert(
            InvoiceItemsCompanion.insert(
              id: itemId,
              invoiceId: invoiceId,
              description: description.trim(),
              quantity: 1,
              unitPrice: amount,
              totalPrice: signedTotal,
              adjustmentType: Value(adjustmentType.name),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final List<InvoiceItemRow> items =
          await (_db.select(_db.invoiceItems)..where(
                (InvoiceItems t) =>
                    t.invoiceId.equals(invoiceId) & t.deletedAt.isNull(),
              ))
              .get();
      final double newTotal = items.fold(
        0,
        (double sum, InvoiceItemRow item) => sum + item.totalPrice,
      );

      await (_db.update(
        _db.invoices,
      )..where((Invoices t) => t.id.equals(invoiceId))).write(
        InvoicesCompanion(totalAmount: Value(newTotal), updatedAt: Value(now)),
      );

      return itemId;
    });
  }

  @override
  Future<void> finalizeInvoice({
    required Role role,
    required String actorUserId,
    required String invoiceId,
  }) async {
    requirePermission(role, Permission.canEditInvoice);

    await _db.transaction(() async {
      final Invoice invoice = await (_db.select(
        _db.invoices,
      )..where((Invoices t) => t.id.equals(invoiceId))).getSingle();

      if (invoice.status != InvoiceStatus.draft.name) {
        throw const InvoiceNotDraftException();
      }

      final DateTime now = DateTime.now().toUtc();

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
    });
  }
}
