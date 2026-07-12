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
    required this.uploadedByName,
    required this.uploadedAt,
  });

  final String id;
  final AttachmentTargetType targetType;
  final String targetId;
  final String fileName;
  final String storagePath;
  final int fileSizeBytes;
  final String uploadedByUserId;
  final String uploadedByName;
  final DateTime uploadedAt;

  /// Lowercased file extension without the leading dot (e.g. `'pdf'`).
  String get fileExtension {
    final int dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) return '';
    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  bool get isImage =>
      fileExtension == 'jpg' ||
      fileExtension == 'jpeg' ||
      fileExtension == 'png';

  bool get isPdf => fileExtension == 'pdf';
}
