import 'package:docentral/features/attachment/domain/attachment_target_type.dart';

/// Domain-facing attachment model, decoupled from Drift's generated row
/// class for the same reason as `PatientRecord` — see beads DocCentral-d0b.
class Attachment {
  const Attachment({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.fileName,
    required this.storagePath,
    required this.fileSizeBytes,
    required this.uploadedByUserId,
    required this.uploadedAt,
  });

  final String id;
  final AttachmentTargetType targetType;
  final String targetId;
  final String fileName;
  final String storagePath;
  final int fileSizeBytes;
  final String uploadedByUserId;
  final DateTime uploadedAt;
}
