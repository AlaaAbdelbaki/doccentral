import 'package:docentral/features/day_closeout/presentation/providers/day_closeout_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/data/providers/current_user_id_provider.dart';
import 'package:docentral/shared/domain/exceptions/permission_denied_exception.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'day_closeout_controller_provider.g.dart';

@riverpod
class DayCloseoutController extends _$DayCloseoutController {
  @override
  FutureOr<void> build() {}

  Future<void> confirmCloseout({
    required DateTime day,
    required double countedCash,
  }) async {
    final Role? role = ref.read(currentRoleProvider);
    final String? actorUserId = ref.read(currentUserIdProvider);
    if (role == null || actorUserId == null) {
      state = AsyncError(
        const PermissionDeniedException(Permission.canConfirmDayCloseout),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(dayCloseoutRepositoryProvider)
          .confirmCloseout(
            role: role,
            actorUserId: actorUserId,
            day: day,
            countedCash: countedCash,
          ),
    );
  }

  Future<void> reopenCloseout({
    required String dayCloseoutId,
    required String reason,
  }) async {
    final Role? role = ref.read(currentRoleProvider);
    final String? actorUserId = ref.read(currentUserIdProvider);
    if (role == null || actorUserId == null) {
      state = AsyncError(
        const PermissionDeniedException(Permission.canReopenDayCloseout),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(dayCloseoutRepositoryProvider)
          .reopenCloseout(
            role: role,
            actorUserId: actorUserId,
            dayCloseoutId: dayCloseoutId,
            reason: reason,
          ),
    );
  }
}
