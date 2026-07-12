import 'package:docentral/features/inventory/domain/stock_adjustment.dart';
import 'package:docentral/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'adjustment_history_provider.g.dart';

@riverpod
Stream<List<StockAdjustment>> adjustmentHistory(
  Ref ref,
  String inventoryItemId,
) {
  final Role? role = ref.watch(currentRoleProvider);
  if (role == null) return Stream.value(const <StockAdjustment>[]);

  return ref
      .watch(inventoryRepositoryProvider)
      .watchAdjustmentHistory(role: role, inventoryItemId: inventoryItemId);
}
