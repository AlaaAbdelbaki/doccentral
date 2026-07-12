import 'package:docentral/features/attachment/domain/attachment_target_type.dart';
import 'package:docentral/features/attachment/presentation/providers/attachment_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/data/providers/current_user_id_provider.dart';
import 'package:docentral/shared/domain/exceptions/permission_denied_exception.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'attachment_controller_provider.g.dart';

@riverpod
class AttachmentController extends _$AttachmentController {
  @override
  FutureOr<void> build() {}

  Future<void> upload({
    required AttachmentTargetType targetType,
    required String targetId,
    required String sourceFilePath,
  }) async {
    final Role? role = ref.read(currentRoleProvider);
    final String? actorUserId = ref.read(currentUserIdProvider);
    if (role == null || actorUserId == null) {
      state = AsyncError(
        const PermissionDeniedException(Permission.canManageAttachments),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(attachmentRepositoryProvider)
          .upload(
            role: role,
            actorUserId: actorUserId,
            targetType: targetType,
            targetId: targetId,
            sourceFilePath: sourceFilePath,
          ),
    );
  }
}
