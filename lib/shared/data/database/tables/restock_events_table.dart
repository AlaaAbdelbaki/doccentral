import 'package:docentral/shared/data/database/mixins/sync_metadata.dart';
import 'package:drift/drift.dart';

@DataClassName('RestockEventRow')
class RestockEvents extends Table with SyncMetadata {
  TextColumn get inventoryItemId => text()();
  IntColumn get quantityAdded => integer()();
  DateTimeColumn get restockDate => dateTime()();
  TextColumn get supplier => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get actorUserId => text()();
}
