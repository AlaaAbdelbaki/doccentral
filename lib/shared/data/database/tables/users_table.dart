import 'package:docentral/shared/data/database/mixins/sync_metadata.dart';
import 'package:drift/drift.dart';

class Users extends Table with SyncMetadata {
  TextColumn get clinicId => text()();
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  TextColumn get email => text()();
  TextColumn get authUserId => text()();
  BoolColumn get isClinicOwner =>
      boolean().withDefault(const Constant(false))();
}
