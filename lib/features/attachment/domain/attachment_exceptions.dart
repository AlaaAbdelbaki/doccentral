enum AttachmentValidationReason { unsupportedFileType, fileTooLarge }

/// Thrown when uploading a file larger than the 10 MB limit, or with an
/// unsupported extension (only PDF, JPG, and PNG are allowed).
class AttachmentValidationException implements Exception {
  const AttachmentValidationException(this.reason);

  final AttachmentValidationReason reason;

  @override
  String toString() => 'AttachmentValidationException: $reason';
}
