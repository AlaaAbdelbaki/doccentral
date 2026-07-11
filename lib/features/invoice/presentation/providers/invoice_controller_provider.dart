import 'package:docentral/features/invoice/domain/invoice_adjustment_type.dart';
import 'package:docentral/features/invoice/presentation/providers/invoice_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/data/providers/current_user_id_provider.dart';
import 'package:docentral/shared/domain/exceptions/permission_denied_exception.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'invoice_controller_provider.g.dart';

@riverpod
class InvoiceController extends _$InvoiceController {
  @override
  FutureOr<void> build() {}

  Future<void> addAdjustment({
    required String invoiceId,
    required InvoiceAdjustmentType adjustmentType,
    required String description,
    required double amount,
  }) async {
    final Role? role = ref.read(currentRoleProvider);
    if (role == null) {
      state = AsyncError(
        const PermissionDeniedException(Permission.canEditInvoice),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(invoiceRepositoryProvider)
          .addAdjustment(
            role: role,
            invoiceId: invoiceId,
            adjustmentType: adjustmentType,
            description: description,
            amount: amount,
          ),
    );
  }

  Future<void> finalizeInvoice({required String invoiceId}) async {
    final Role? role = ref.read(currentRoleProvider);
    final String? actorUserId = ref.read(currentUserIdProvider);
    if (role == null || actorUserId == null) {
      state = AsyncError(
        const PermissionDeniedException(Permission.canEditInvoice),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(invoiceRepositoryProvider)
          .finalizeInvoice(
            role: role,
            actorUserId: actorUserId,
            invoiceId: invoiceId,
          ),
    );
  }
}
