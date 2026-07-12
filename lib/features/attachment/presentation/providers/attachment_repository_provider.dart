import 'package:docentral/features/attachment/data/attachment_repository_impl.dart';
import 'package:docentral/features/attachment/domain/attachment_repository.dart';
import 'package:docentral/shared/data/providers/app_database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'attachment_repository_provider.g.dart';

@riverpod
AttachmentRepository attachmentRepository(Ref ref) {
  return AttachmentRepositoryImpl(ref.watch(appDatabaseProvider));
}
