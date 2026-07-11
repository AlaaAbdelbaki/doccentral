import 'package:docentral/shared/data/database/mixins/sync_metadata.dart';
import 'package:drift/drift.dart';

@DataClassName('InvoiceItemRow')
class InvoiceItems extends Table with SyncMetadata {
  TextColumn get invoiceId => text()();
  TextColumn get description => text()();
  TextColumn get toothNumber => text().nullable()();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
  RealColumn get totalPrice => real()();
  // Null for items mirroring a Performed Treatment; set to 'discount' or
  // 'surcharge' for adjustment line items added in Story 7.1.
  TextColumn get adjustmentType => text().nullable()();
}
