import 'package:drift/drift.dart';

mixin SyncMetadata on Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  // 'pending' | 'synced' | 'conflict'
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}
