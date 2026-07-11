import 'package:docentral/shared/data/database/mixins/sync_metadata.dart';
import 'package:drift/drift.dart';

@DataClassName('PerformedTreatmentRow')
class PerformedTreatments extends Table with SyncMetadata {
  TextColumn get visitId => text()();
  TextColumn get toothNumber => text()();
  TextColumn get procedureName => text()();
  RealColumn get unitPrice => real()();
  IntColumn get quantity => integer()();
  TextColumn get recordedByUserId => text()();
}
