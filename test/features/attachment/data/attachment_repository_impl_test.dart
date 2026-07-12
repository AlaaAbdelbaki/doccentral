import 'dart:io';

import 'package:docentral/features/attachment/data/attachment_repository_impl.dart';
import 'package:docentral/features/attachment/domain/attachment.dart';
import 'package:docentral/features/attachment/domain/attachment_exceptions.dart';
import 'package:docentral/features/attachment/domain/attachment_target_type.dart';
import 'package:docentral/shared/data/database/app_database.dart';
import 'package:docentral/shared/domain/exceptions/permission_denied_exception.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

AppDatabase _createInMemoryDatabase() {
  return AppDatabase(NativeDatabase.memory());
}

void main() {
  late AppDatabase db;
  late Directory sourceDir;
  late Directory storageDir;
  late AttachmentRepositoryImpl repository;

  setUp(() async {
    db = _createInMemoryDatabase();
    sourceDir = await Directory.systemTemp.createTemp('attachment_src_');
    storageDir = await Directory.systemTemp.createTemp('attachment_store_');
    repository = AttachmentRepositoryImpl(
      db,
      storageDirectoryProvider: () async => storageDir,
    );
  });

  tearDown(() async {
    await db.close();
    await sourceDir.delete(recursive: true);
    await storageDir.delete(recursive: true);
  });

  Future<String> createSourceFile(String name, List<int> bytes) async {
    final File file = File(p.join(sourceDir.path, name));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  group('AttachmentRepositoryImpl.upload', () {
    test(
      'copies the file into local storage and creates an Attachment record',
      () async {
        final String sourcePath = await createSourceFile(
          'xray.jpg',
          List<int>.filled(1024, 1),
        );

        final String id = await repository.upload(
          role: Role.assistant,
          actorUserId: 'actor-1',
          targetType: AttachmentTargetType.patient,
          targetId: 'patient-1',
          sourceFilePath: sourcePath,
        );

        final List<Attachment> attachments = await repository
            .watchForTarget(
              role: Role.assistant,
              targetType: AttachmentTargetType.patient,
              targetId: 'patient-1',
            )
            .first;

        expect(attachments.single.id, id);
        expect(attachments.single.fileName, 'xray.jpg');
        expect(attachments.single.fileSizeBytes, 1024);
        expect(attachments.single.uploadedByUserId, 'actor-1');
        expect(File(attachments.single.storagePath).existsSync(), isTrue);
      },
    );

    test(
      'throws AttachmentValidationException for a file over 10 MB',
      () async {
        final String sourcePath = await createSourceFile(
          'big.pdf',
          List<int>.filled(AttachmentRepositoryImpl.maxFileSizeBytes + 1, 1),
        );

        expect(
          () => repository.upload(
            role: Role.assistant,
            actorUserId: 'actor-1',
            targetType: AttachmentTargetType.patient,
            targetId: 'patient-1',
            sourceFilePath: sourcePath,
          ),
          throwsA(
            isA<AttachmentValidationException>().having(
              (AttachmentValidationException e) => e.reason,
              'reason',
              AttachmentValidationReason.fileTooLarge,
            ),
          ),
        );
      },
    );

    test(
      'throws AttachmentValidationException for an unsupported file type',
      () async {
        final String sourcePath = await createSourceFile('notes.txt', [1, 2]);

        expect(
          () => repository.upload(
            role: Role.assistant,
            actorUserId: 'actor-1',
            targetType: AttachmentTargetType.patient,
            targetId: 'patient-1',
            sourceFilePath: sourcePath,
          ),
          throwsA(
            isA<AttachmentValidationException>().having(
              (AttachmentValidationException e) => e.reason,
              'reason',
              AttachmentValidationReason.unsupportedFileType,
            ),
          ),
        );
      },
    );

    test('accepts pdf, jpg, jpeg, and png extensions', () async {
      for (final String ext in <String>['pdf', 'jpg', 'jpeg', 'png']) {
        final String sourcePath = await createSourceFile('file.$ext', <int>[
          1,
          2,
          3,
        ]);

        final String id = await repository.upload(
          role: Role.assistant,
          actorUserId: 'actor-1',
          targetType: AttachmentTargetType.visit,
          targetId: 'visit-1',
          sourceFilePath: sourcePath,
        );

        expect(id, isNotEmpty);
      }
    });

    test('throws PermissionDeniedException for a Nurse', () async {
      final String sourcePath = await createSourceFile('xray.jpg', [1, 2]);

      expect(
        () => repository.upload(
          role: Role.nurse,
          actorUserId: 'actor-1',
          targetType: AttachmentTargetType.patient,
          targetId: 'patient-1',
          sourceFilePath: sourcePath,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });
  });

  group('AttachmentRepositoryImpl.watchForTarget', () {
    test('does not mix attachments across different targets', () async {
      final String sourcePath = await createSourceFile('xray.jpg', [1, 2]);
      await repository.upload(
        role: Role.assistant,
        actorUserId: 'actor-1',
        targetType: AttachmentTargetType.patient,
        targetId: 'patient-1',
        sourceFilePath: sourcePath,
      );
      await repository.upload(
        role: Role.assistant,
        actorUserId: 'actor-1',
        targetType: AttachmentTargetType.visit,
        targetId: 'visit-1',
        sourceFilePath: sourcePath,
      );

      final List<Attachment> patientAttachments = await repository
          .watchForTarget(
            role: Role.assistant,
            targetType: AttachmentTargetType.patient,
            targetId: 'patient-1',
          )
          .first;
      final List<Attachment> visitAttachments = await repository
          .watchForTarget(
            role: Role.assistant,
            targetType: AttachmentTargetType.visit,
            targetId: 'visit-1',
          )
          .first;

      expect(patientAttachments, hasLength(1));
      expect(visitAttachments, hasLength(1));
    });

    test('all three roles can view attachments', () async {
      final String sourcePath = await createSourceFile('xray.jpg', [1, 2]);
      await repository.upload(
        role: Role.assistant,
        actorUserId: 'actor-1',
        targetType: AttachmentTargetType.patient,
        targetId: 'patient-1',
        sourceFilePath: sourcePath,
      );

      for (final Role role in Role.values) {
        final List<Attachment> attachments = await repository
            .watchForTarget(
              role: role,
              targetType: AttachmentTargetType.patient,
              targetId: 'patient-1',
            )
            .first;
        expect(attachments, hasLength(1), reason: '$role');
      }
    });
  });
}
