import 'package:docentral/features/attachment/domain/attachment.dart';
import 'package:docentral/features/attachment/domain/attachment_target_type.dart';
import 'package:docentral/features/attachment/presentation/providers/attachment_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'attachments_for_target_provider.g.dart';

@riverpod
Stream<List<Attachment>> attachmentsForTarget(
  Ref ref,
  AttachmentTargetType targetType,
  String targetId,
) {
  final Role? role = ref.watch(currentRoleProvider);
  if (role == null) return Stream.value(const <Attachment>[]);

  return ref
      .watch(attachmentRepositoryProvider)
      .watchForTarget(role: role, targetType: targetType, targetId: targetId);
}
