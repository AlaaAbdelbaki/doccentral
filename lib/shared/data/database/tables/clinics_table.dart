import 'package:docentral/shared/data/database/mixins/sync_metadata.dart';
import 'package:drift/drift.dart';

class Clinics extends Table with SyncMetadata {
  TextColumn get name => text()();
  TextColumn get address => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get invoiceFooter => text().nullable()();
  TextColumn get logoPath => text().nullable()();
  TextColumn get locale => text().withDefault(const Constant('fr-TN'))();
  TextColumn get currency => text().withDefault(const Constant('TND'))();
}
