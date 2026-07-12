import 'package:docentral/shared/data/database/mixins/sync_metadata.dart';
import 'package:drift/drift.dart';

@DataClassName('StockAdjustmentRow')
class StockAdjustments extends Table with SyncMetadata {
  TextColumn get inventoryItemId => text()();
  IntColumn get oldQuantity => integer()();
  IntColumn get newQuantity => integer()();
  IntColumn get delta => integer()();
  TextColumn get reason => text()();
  TextColumn get actorUserId => text()();
}
