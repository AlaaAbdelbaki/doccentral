import 'package:docentral/shared/data/database/mixins/sync_metadata.dart';
import 'package:drift/drift.dart';

class InvoiceVoids extends Table with SyncMetadata {
  TextColumn get invoiceId => text()();
  TextColumn get actorUserId => text()();
  TextColumn get reason => text()();
}
