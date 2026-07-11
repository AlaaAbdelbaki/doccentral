import 'package:docentral/shared/data/database/mixins/sync_metadata.dart';
import 'package:drift/drift.dart';

class Visits extends Table with SyncMetadata {
  TextColumn get appointmentId => text()();
  TextColumn get patientId => text()();
  TextColumn get dentistId => text()();
  TextColumn get status => text().withDefault(const Constant('checkedIn'))();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get inProgressAt => dateTime().nullable()();
}
