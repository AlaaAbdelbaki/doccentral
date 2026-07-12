import 'package:docentral/shared/data/database/mixins/sync_metadata.dart';
import 'package:drift/drift.dart';

@DataClassName('AttachmentRow')
class Attachments extends Table with SyncMetadata {
  TextColumn get targetType => text()();
  TextColumn get targetId => text()();
  TextColumn get fileName => text()();
  TextColumn get storagePath => text()();
  IntColumn get fileSizeBytes => integer()();
  TextColumn get uploadedByUserId => text()();
}
