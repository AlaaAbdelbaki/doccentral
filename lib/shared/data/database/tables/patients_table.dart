import 'package:docentral/shared/data/database/mixins/sync_metadata.dart';
import 'package:drift/drift.dart';

class Patients extends Table with SyncMetadata {
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  DateTimeColumn get dateOfBirth => dateTime()();
  TextColumn get phone => text()();
  TextColumn get email => text().nullable()();
  TextColumn get historyNotes => text().nullable()();
}
