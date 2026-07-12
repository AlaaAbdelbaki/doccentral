import 'package:docentral/features/inventory/domain/restock_event.dart';
import 'package:docentral/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'restock_history_provider.g.dart';

@riverpod
Stream<List<RestockEvent>> restockHistory(Ref ref, String inventoryItemId) {
  final Role? role = ref.watch(currentRoleProvider);
  if (role == null) return Stream.value(const <RestockEvent>[]);

  return ref
      .watch(inventoryRepositoryProvider)
      .watchRestockHistory(role: role, inventoryItemId: inventoryItemId);
}
