import 'package:docentral/shared/data/database/mixins/sync_metadata.dart';
import 'package:drift/drift.dart';

class Appointments extends Table with SyncMetadata {
  TextColumn get patientId => text()();
  TextColumn get assignedUserId => text()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  TextColumn get status => text().withDefault(const Constant('scheduled'))();
  TextColumn get reason => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get rescheduledToAppointmentId => text().nullable()();
}
