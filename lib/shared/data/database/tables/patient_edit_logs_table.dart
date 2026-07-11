import 'package:docentral/shared/data/database/mixins/sync_metadata.dart';
import 'package:drift/drift.dart';

class PatientEditLogs extends Table with SyncMetadata {
  TextColumn get patientId => text()();
  TextColumn get actorUserId => text()();
  TextColumn get changedFields => text()();
}
