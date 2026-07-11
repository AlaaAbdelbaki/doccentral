import 'package:docentral/shared/data/database/mixins/sync_metadata.dart';
import 'package:drift/drift.dart';

class Invoices extends Table with SyncMetadata {
  TextColumn get patientId => text()();
  TextColumn get visitId => text()();
  RealColumn get totalAmount => real()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get createdByUserId => text()();
}
