import 'package:docentral/features/attachment/domain/attachment.dart';
import 'package:docentral/features/attachment/domain/attachment_target_type.dart';
import 'package:docentral/shared/domain/rbac/role.dart';

abstract class AttachmentRepository {
  /// Copies the file at [sourceFilePath] into local app storage and creates
  /// an Attachment record linking it to the Patient or Visit identified by
  /// [targetType]/[targetId]. Returns the new attachment's id.
  ///
  /// Throws [AttachmentValidationException] if the file exceeds 10 MB or
  /// has an unsupported extension (only PDF, JPG, and PNG are allowed).
  Future<String> upload({
    required Role role,
    required String actorUserId,
    required AttachmentTargetType targetType,
    required String targetId,
    required String sourceFilePath,
  });

  /// Streams Attachments linked to the Patient or Visit identified by
  /// [targetType]/[targetId], oldest first.
  Stream<List<Attachment>> watchForTarget({
    required Role role,
    required AttachmentTargetType targetType,
    required String targetId,
  });
}
