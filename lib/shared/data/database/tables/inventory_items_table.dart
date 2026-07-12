import 'package:docentral/shared/data/database/mixins/sync_metadata.dart';
import 'package:drift/drift.dart';

@DataClassName('InventoryItemRow')
class InventoryItems extends Table with SyncMetadata {
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get unit => text()();
  IntColumn get onHandQuantity => integer()();
  IntColumn get lowStockThreshold => integer()();
}
