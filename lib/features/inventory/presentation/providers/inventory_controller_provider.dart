import 'package:docentral/features/inventory/domain/inventory_category.dart';
import 'package:docentral/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/data/providers/current_user_id_provider.dart';
import 'package:docentral/shared/domain/exceptions/permission_denied_exception.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'inventory_controller_provider.g.dart';

@riverpod
class InventoryController extends _$InventoryController {
  @override
  FutureOr<void> build() {}

  Future<void> create({
    required String name,
    required InventoryCategory category,
    required String unit,
    required int onHandQuantity,
    required int lowStockThreshold,
  }) async {
    final Role? role = ref.read(currentRoleProvider);
    if (role == null) {
      state = AsyncError(
        const PermissionDeniedException(Permission.canManageInventory),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(inventoryRepositoryProvider)
          .create(
            role: role,
            name: name,
            category: category,
            unit: unit,
            onHandQuantity: onHandQuantity,
            lowStockThreshold: lowStockThreshold,
          ),
    );
  }

  Future<void> recordRestock({
    required String inventoryItemId,
    required int quantityAdded,
    DateTime? restockDate,
    String? supplier,
    String? notes,
  }) async {
    final Role? role = ref.read(currentRoleProvider);
    final String? actorUserId = ref.read(currentUserIdProvider);
    if (role == null || actorUserId == null) {
      state = AsyncError(
        const PermissionDeniedException(Permission.canManageInventory),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(inventoryRepositoryProvider)
          .recordRestock(
            role: role,
            actorUserId: actorUserId,
            inventoryItemId: inventoryItemId,
            quantityAdded: quantityAdded,
            restockDate: restockDate,
            supplier: supplier,
            notes: notes,
          ),
    );
  }

  Future<void> adjustStock({
    required String inventoryItemId,
    required int newQuantity,
    required String reason,
  }) async {
    final Role? role = ref.read(currentRoleProvider);
    final String? actorUserId = ref.read(currentUserIdProvider);
    if (role == null || actorUserId == null) {
      state = AsyncError(
        const PermissionDeniedException(Permission.canManageInventory),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(inventoryRepositoryProvider)
          .adjustStock(
            role: role,
            actorUserId: actorUserId,
            inventoryItemId: inventoryItemId,
            newQuantity: newQuantity,
            reason: reason,
          ),
    );
  }
}
