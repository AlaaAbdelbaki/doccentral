import 'package:docentral/shared/data/database/mixins/sync_metadata.dart';
import 'package:drift/drift.dart';

class AppointmentCancellations extends Table with SyncMetadata {
  TextColumn get appointmentId => text()();
  TextColumn get actorUserId => text()();
  // Stores the CancellationReason enum's own `.name`.
  TextColumn get reason => text()();
}
