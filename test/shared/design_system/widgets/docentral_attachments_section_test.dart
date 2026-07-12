import 'package:docentral/features/attachment/domain/attachment.dart';
import 'package:docentral/features/attachment/domain/attachment_repository.dart';
import 'package:docentral/features/attachment/domain/attachment_target_type.dart';
import 'package:docentral/features/attachment/presentation/providers/attachment_repository_provider.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/design_system/widgets/docentral_attachments_section.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAttachmentRepository implements AttachmentRepository {
  _FakeAttachmentRepository(this._attachments);

  final List<Attachment> _attachments;

  @override
  Future<String> upload({
    required Role role,
    required String actorUserId,
    required AttachmentTargetType targetType,
    required String targetId,
    required String sourceFilePath,
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Stream<List<Attachment>> watchForTarget({
    required Role role,
    required AttachmentTargetType targetType,
    required String targetId,
  }) => Stream.value(_attachments);
}

Future<void> _pumpSection(
  WidgetTester tester, {
  List<Attachment> attachments = const <Attachment>[],
  bool canManage = true,
  Role role = Role.assistant,
}) async {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      attachmentRepositoryProvider.overrideWithValue(
        _FakeAttachmentRepository(attachments),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.read(currentRoleProvider.notifier).setRole(role);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DocCentralAttachmentsSection(
            title: 'Attachments',
            targetType: AttachmentTargetType.patient,
            targetId: 'patient-1',
            canManage: canManage,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the empty state when there are no attachments', (
    WidgetTester tester,
  ) async {
    await _pumpSection(tester);

    expect(find.text('No attachments yet'), findsOneWidget);
  });

  testWidgets('renders each attachment with its file name', (
    WidgetTester tester,
  ) async {
    await _pumpSection(
      tester,
      attachments: <Attachment>[
        Attachment(
          id: '1',
          targetType: AttachmentTargetType.patient,
          targetId: 'patient-1',
          fileName: 'xray.jpg',
          storagePath: '/tmp/xray.jpg',
          fileSizeBytes: 2048,
          uploadedByUserId: 'actor-1',
          uploadedAt: DateTime(2026, 6, 8),
        ),
      ],
    );

    expect(find.text('xray.jpg'), findsOneWidget);
    expect(find.text('No attachments yet'), findsNothing);
  });

  testWidgets('the Upload file button is hidden when canManage is false', (
    WidgetTester tester,
  ) async {
    await _pumpSection(tester, canManage: false);

    expect(find.text('Upload file'), findsNothing);
  });

  testWidgets('the Upload file button is shown when canManage is true', (
    WidgetTester tester,
  ) async {
    await _pumpSection(tester);

    expect(find.text('Upload file'), findsOneWidget);
  });
}
