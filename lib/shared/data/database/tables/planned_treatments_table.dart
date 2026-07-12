import 'package:docentral/shared/data/database/mixins/sync_metadata.dart';
import 'package:drift/drift.dart';

@DataClassName('PlannedTreatmentRow')
class PlannedTreatments extends Table with SyncMetadata {
  TextColumn get patientId => text()();
  TextColumn get procedureName => text()();
  TextColumn get toothNumber => text()();
  RealColumn get estimatedUnitPrice => real()();
  IntColumn get sequenceNumber => integer()();
  DateTimeColumn get targetDate => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('planned'))();
}
