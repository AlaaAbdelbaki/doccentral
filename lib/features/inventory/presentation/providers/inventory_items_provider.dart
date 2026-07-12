import 'package:docentral/features/inventory/domain/inventory_item.dart';
import 'package:docentral/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'inventory_items_provider.g.dart';

@riverpod
Stream<List<InventoryItem>> inventoryItems(Ref ref) {
  final Role? role = ref.watch(currentRoleProvider);
  if (role == null) return Stream.value(const <InventoryItem>[]);

  return ref.watch(inventoryRepositoryProvider).watchAll(role: role);
}
