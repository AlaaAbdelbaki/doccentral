import 'package:docentral/features/inventory/data/inventory_repository_impl.dart';
import 'package:docentral/features/inventory/domain/inventory_repository.dart';
import 'package:docentral/shared/data/providers/app_database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'inventory_repository_provider.g.dart';

@riverpod
InventoryRepository inventoryRepository(Ref ref) {
  return InventoryRepositoryImpl(ref.watch(appDatabaseProvider));
}
