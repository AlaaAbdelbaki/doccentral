import 'package:docentral/shared/data/database/mixins/sync_metadata.dart';
import 'package:drift/drift.dart';

@DataClassName('RoleRow')
class Roles extends Table with SyncMetadata {
  TextColumn get clinicId => text()();
  // Stores the Role enum's own `.name` (e.g. Role.doctor.name == 'doctor').
  TextColumn get name => text()();
}
