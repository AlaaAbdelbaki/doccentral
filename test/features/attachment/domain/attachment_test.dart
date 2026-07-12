import 'package:docentral/features/attachment/domain/attachment.dart';
import 'package:docentral/features/attachment/domain/attachment_target_type.dart';
import 'package:flutter_test/flutter_test.dart';

Attachment _attachment(String fileName) => Attachment(
  id: '1',
  targetType: AttachmentTargetType.patient,
  targetId: 'patient-1',
  fileName: fileName,
  storagePath: '/tmp/$fileName',
  fileSizeBytes: 1024,
  uploadedByUserId: 'actor-1',
  uploadedByName: 'Sami Gharbi',
  uploadedAt: DateTime(2026, 6, 8),
);

void main() {
  group('Attachment.fileExtension', () {
    test('is the lowercased extension without the dot', () {
      expect(_attachment('xray.JPG').fileExtension, 'jpg');
      expect(_attachment('report.pdf').fileExtension, 'pdf');
    });

    test('is empty for a file name with no extension', () {
      expect(_attachment('README').fileExtension, isEmpty);
    });
  });

  group('Attachment.isImage / isPdf', () {
    test('jpg, jpeg, and png are images, not pdfs', () {
      for (final String ext in <String>['jpg', 'jpeg', 'png']) {
        final Attachment a = _attachment('file.$ext');
        expect(a.isImage, isTrue, reason: ext);
        expect(a.isPdf, isFalse, reason: ext);
      }
    });

    test('pdf is a pdf, not an image', () {
      final Attachment a = _attachment('file.pdf');
      expect(a.isPdf, isTrue);
      expect(a.isImage, isFalse);
    });
  });
}
