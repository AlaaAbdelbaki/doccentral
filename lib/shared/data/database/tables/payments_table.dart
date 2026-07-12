import 'package:docentral/shared/data/database/mixins/sync_metadata.dart';
import 'package:drift/drift.dart';

@DataClassName('PaymentRow')
class Payments extends Table with SyncMetadata {
  TextColumn get invoiceId => text()();
  RealColumn get amount => real()();
  TextColumn get method => text().withDefault(const Constant('cash'))();
  DateTimeColumn get paymentDate => dateTime()();
  TextColumn get notes => text().nullable()();
  TextColumn get recordedByUserId => text()();
}
