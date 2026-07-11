import 'package:docentral/shared/data/database/mixins/sync_metadata.dart';
import 'package:drift/drift.dart';

class UserRoles extends Table with SyncMetadata {
  TextColumn get userId => text()();
  TextColumn get roleId => text()();
}
