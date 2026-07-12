import 'package:docentral/features/attachment/domain/attachment.dart';
import 'package:docentral/features/attachment/domain/attachment_exceptions.dart';
import 'package:docentral/features/attachment/domain/attachment_target_type.dart';
import 'package:docentral/features/attachment/presentation/providers/attachment_controller_provider.dart';
import 'package:docentral/features/attachment/presentation/providers/attachments_for_target_provider.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/design_system/app_spacing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Shared attachments list + upload control, used on both the Patient File
/// and the Visit detail page.
class DocCentralAttachmentsSection extends ConsumerWidget {
  const DocCentralAttachmentsSection({
    super.key,
    required this.title,
    required this.targetType,
    required this.targetId,
    required this.canManage,
  });

  final String title;
  final AttachmentTargetType targetType;
  final String targetId;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AsyncValue<List<Attachment>> attachmentsAsync = ref.watch(
      attachmentsForTargetProvider(targetType, targetId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            if (canManage)
              TextButton.icon(
                onPressed: () => _pickAndUpload(context, ref),
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(l10n.attachmentsUploadButton),
              ),
          ],
        ),
        attachmentsAsync.when(
          data: (List<Attachment> attachments) {
            if (attachments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(l10n.attachmentsEmptyState),
              );
            }
            return Column(
              children: <Widget>[
                for (final Attachment attachment in attachments)
                  _AttachmentRow(attachment: attachment),
              ],
            );
          },
          error: (Object error, StackTrace stackTrace) => Text('$error'),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: LinearProgressIndicator(),
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf', 'jpg', 'jpeg', 'png'],
    );
    final String? path = result?.files.single.path;
    if (path == null) return;

    await ref
        .read(attachmentControllerProvider.notifier)
        .upload(
          targetType: targetType,
          targetId: targetId,
          sourceFilePath: path,
        );

    if (!context.mounted) return;
    final Object? error = ref.read(attachmentControllerProvider).error;
    if (error is AttachmentValidationException) {
      final AppLocalizations l10n = AppLocalizations.of(context)!;
      final String message = switch (error.reason) {
        AttachmentValidationReason.unsupportedFileType =>
          l10n.attachmentsUnsupportedFileTypeError,
        AttachmentValidationReason.fileTooLarge =>
          l10n.attachmentsFileTooLargeError,
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({required this.attachment});

  final Attachment attachment;

  static String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          const Icon(Icons.attach_file, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(attachment.fileName)),
          Text(_formatSize(attachment.fileSizeBytes)),
          const SizedBox(width: AppSpacing.sm),
          Text(DateFormat('dd/MM/yyyy').format(attachment.uploadedAt)),
        ],
      ),
    );
  }
}
