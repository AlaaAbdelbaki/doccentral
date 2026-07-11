import 'package:docentral/shared/data/database/mixins/sync_metadata.dart';
import 'package:drift/drift.dart';

class VisitUnlockLogs extends Table with SyncMetadata {
  TextColumn get visitId => text()();
  TextColumn get actorUserId => text()();
  TextColumn get reason => text()();
}
