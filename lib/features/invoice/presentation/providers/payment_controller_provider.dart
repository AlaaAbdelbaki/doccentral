import 'package:docentral/features/invoice/domain/payment_method.dart';
import 'package:docentral/features/invoice/presentation/providers/payment_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/data/providers/current_user_id_provider.dart';
import 'package:docentral/shared/domain/exceptions/permission_denied_exception.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'payment_controller_provider.g.dart';

@riverpod
class PaymentController extends _$PaymentController {
  @override
  FutureOr<void> build() {}

  Future<void> recordPayment({
    required String invoiceId,
    required double amount,
    PaymentMethod method = PaymentMethod.cash,
    DateTime? paymentDate,
    String? notes,
  }) async {
    final Role? role = ref.read(currentRoleProvider);
    final String? actorUserId = ref.read(currentUserIdProvider);
    if (role == null || actorUserId == null) {
      state = AsyncError(
        const PermissionDeniedException(Permission.canRecordPayment),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(paymentRepositoryProvider)
          .recordPayment(
            role: role,
            actorUserId: actorUserId,
            invoiceId: invoiceId,
            amount: amount,
            method: method,
            paymentDate: paymentDate,
            notes: notes,
          ),
    );
  }
}
