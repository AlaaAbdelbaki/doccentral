import 'package:docentral/shared/data/database/mixins/sync_metadata.dart';
import 'package:drift/drift.dart';

class DayCloseoutReopenLogs extends Table with SyncMetadata {
  TextColumn get dayCloseoutId => text()();
  TextColumn get actorUserId => text()();
  TextColumn get reason => text()();
}
