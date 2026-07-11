import 'package:docentral/shared/data/database/mixins/sync_metadata.dart';
import 'package:drift/drift.dart';

class AppointmentEditLogs extends Table with SyncMetadata {
  TextColumn get appointmentId => text()();
  TextColumn get actorUserId => text()();
  TextColumn get changedFields => text()();
}
