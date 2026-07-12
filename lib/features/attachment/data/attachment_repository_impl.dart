import 'dart:io';

import 'package:docentral/features/attachment/domain/attachment.dart';
import 'package:docentral/features/attachment/domain/attachment_exceptions.dart';
import 'package:docentral/features/attachment/domain/attachment_repository.dart';
import 'package:docentral/features/attachment/domain/attachment_target_type.dart';
import 'package:docentral/shared/data/database/app_database.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/permission_guard.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class AttachmentRepositoryImpl implements AttachmentRepository {
  AttachmentRepositoryImpl(
    this._db, {
    Uuid uuid = const Uuid(),
    Future<Directory> Function()? storageDirectoryProvider,
  }) : _uuid = uuid,
       _storageDirectoryProvider =
           storageDirectoryProvider ?? _defaultStorageDirectory;

  static const int maxFileSizeBytes = 10 * 1024 * 1024;
  static const Set<String> allowedExtensions = {'pdf', 'jpg', 'jpeg', 'png'};

  final AppDatabase _db;
  final Uuid _uuid;
  final Future<Directory> Function() _storageDirectoryProvider;

  static Future<Directory> _defaultStorageDirectory() async {
    final Directory docsDir = await getApplicationDocumentsDirectory();
    final Directory attachmentsDir = Directory(
      p.join(docsDir.path, 'attachments'),
    );
    await attachmentsDir.create(recursive: true);
    return attachmentsDir;
  }

  @override
  Future<String> upload({
    required Role role,
    required String actorUserId,
    required AttachmentTargetType targetType,
    required String targetId,
    required String sourceFilePath,
  }) async {
    requirePermission(role, Permission.canManageAttachments);

    final String fileName = p.basename(sourceFilePath);
    final String extension = p
        .extension(fileName)
        .replaceFirst('.', '')
        .toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      throw const AttachmentValidationException(
        AttachmentValidationReason.unsupportedFileType,
      );
    }

    final File sourceFile = File(sourceFilePath);
    final int fileSizeBytes = await sourceFile.length();
    if (fileSizeBytes > maxFileSizeBytes) {
      throw const AttachmentValidationException(
        AttachmentValidationReason.fileTooLarge,
      );
    }

    final String id = _uuid.v4();
    final Directory storageDir = await _storageDirectoryProvider();
    final String storagePath = p.join(storageDir.path, '$id-$fileName');
    await sourceFile.copy(storagePath);

    final DateTime now = DateTime.now().toUtc();
    await _db
        .into(_db.attachments)
        .insert(
          AttachmentsCompanion.insert(
            id: id,
            targetType: targetType.name,
            targetId: targetId,
            fileName: fileName,
            storagePath: storagePath,
            fileSizeBytes: fileSizeBytes,
            uploadedByUserId: actorUserId,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  @override
  Stream<List<Attachment>> watchForTarget({
    required Role role,
    required AttachmentTargetType targetType,
    required String targetId,
  }) {
    requirePermission(role, Permission.canViewAttachments);

    final JoinedSelectStatement<HasResultSet, dynamic> query =
        _db.select(_db.attachments).join([
            leftOuterJoin(
              _db.users,
              _db.users.id.equalsExp(_db.attachments.uploadedByUserId),
            ),
          ])
          ..where(
            _db.attachments.deletedAt.isNull() &
                _db.attachments.targetType.equals(targetType.name) &
                _db.attachments.targetId.equals(targetId),
          )
          ..orderBy([OrderingTerm.asc(_db.attachments.createdAt)]);

    return query.watch().map(
      (List<TypedResult> rows) => rows.map(_toDomain).toList(growable: false),
    );
  }

  Attachment _toDomain(TypedResult row) {
    final AttachmentRow attachment = row.readTable(_db.attachments);
    final User? uploader = row.readTableOrNull(_db.users);
    return Attachment(
      id: attachment.id,
      targetType: AttachmentTargetType.values.byName(attachment.targetType),
      targetId: attachment.targetId,
      fileName: attachment.fileName,
      storagePath: attachment.storagePath,
      fileSizeBytes: attachment.fileSizeBytes,
      uploadedByUserId: attachment.uploadedByUserId,
      uploadedByName: uploader == null
          ? attachment.uploadedByUserId
          : '${uploader.firstName} ${uploader.lastName}',
      uploadedAt: attachment.createdAt,
    );
  }
}
