import 'package:docentral/features/appointment/presentation/providers/linked_planned_treatments_provider.dart';
import 'package:docentral/features/attachment/domain/attachment_target_type.dart';
import 'package:docentral/features/invoice/presentation/invoice_detail_page.dart';
import 'package:docentral/features/treatment_plan/domain/planned_treatment.dart';
import 'package:docentral/features/treatment_plan/domain/planned_treatment_exceptions.dart';
import 'package:docentral/features/treatment_plan/domain/planned_treatment_status.dart';
import 'package:docentral/features/visit/domain/performed_treatment.dart';
import 'package:docentral/features/visit/domain/visit_exceptions.dart';
import 'package:docentral/features/visit/domain/visit_record.dart';
import 'package:docentral/features/visit/domain/visit_status.dart';
import 'package:docentral/features/visit/presentation/providers/performed_treatment_controller_provider.dart';
import 'package:docentral/features/visit/presentation/providers/performed_treatments_provider.dart';
import 'package:docentral/features/visit/presentation/providers/visit_controller_provider.dart';
import 'package:docentral/features/visit/presentation/providers/visit_for_appointment_provider.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/providers/permission_provider.dart';
import 'package:docentral/shared/design_system/app_spacing.dart';
import 'package:docentral/shared/design_system/widgets/docentral_attachments_section.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

part 'widgets/clinical_record_section.dart';
part 'widgets/planned_treatments_to_perform_section.dart';
part 'widgets/treatment_form_dialog.dart';
part 'widgets/treatment_row.dart';
part 'widgets/unlock_visit_dialog.dart';

class VisitDetailPage extends ConsumerWidget {
  const VisitDetailPage({
    super.key,
    required this.appointmentId,
    required this.patientName,
  });

  final String appointmentId;
  final String patientName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final VisitRecord? visit = ref
        .watch(visitForAppointmentProvider(appointmentId))
        .value;
    final bool canEditVisit = ref.watch(permissionCheckerProvider)(
      Permission.canEditVisit,
    );

    if (visit == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.visitDetailPageTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final bool canEditTreatments =
        canEditVisit && visit.status == VisitStatus.inProgress;
    final bool canCompleteVisit = ref.watch(permissionCheckerProvider)(
      Permission.canCompleteVisit,
    );
    final AsyncValue<List<PerformedTreatment>> treatmentsAsync = ref.watch(
      performedTreatmentsProvider(visit.id),
    );
    final bool hasTreatments = treatmentsAsync.value?.isNotEmpty ?? false;
    final bool canComplete =
        canCompleteVisit &&
        visit.status == VisitStatus.inProgress &&
        hasTreatments;
    final bool canUnlock =
        ref.watch(permissionCheckerProvider)(Permission.canUnlockVisit) &&
        visit.status == VisitStatus.completed;
    final bool canViewInvoice =
        ref.watch(permissionCheckerProvider)(Permission.canEditInvoice) &&
        visit.status == VisitStatus.completed;
    final bool canManageAttachments = ref.watch(permissionCheckerProvider)(
      Permission.canManageAttachments,
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(l10n.visitDetailPageTitle),
            Text(patientName, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: <Widget>[
          if (canEditTreatments)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: FilledButton.icon(
                onPressed: () =>
                    _showTreatmentFormDialog(context, ref, visitId: visit.id),
                icon: const Icon(Icons.add),
                label: Text(l10n.visitAddTreatmentButton),
              ),
            ),
          if (canComplete)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: OutlinedButton.icon(
                onPressed: () => _confirmCompleteVisit(context, ref, visit.id),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(l10n.visitCompleteButton),
              ),
            ),
          if (canUnlock)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: OutlinedButton.icon(
                onPressed: () => _confirmUnlockVisit(context, ref, visit.id),
                icon: const Icon(Icons.lock_open),
                label: Text(l10n.visitUnlockButton),
              ),
            ),
          if (canViewInvoice)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: OutlinedButton.icon(
                onPressed: () => _viewInvoice(context, visit.id),
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text(l10n.visitViewInvoiceButton),
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _ClinicalRecordSection(
            key: ValueKey<String>(visit.id),
            visitId: visit.id,
            diagnosis: visit.diagnosis,
            clinicalNotes: visit.clinicalNotes,
            editable: visit.status == VisitStatus.inProgress,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: DocCentralAttachmentsSection(
              title: l10n.visitAttachmentsSection,
              targetType: AttachmentTargetType.visit,
              targetId: visit.id,
              canManage: canManageAttachments,
            ),
          ),
          if (canEditTreatments)
            _PlannedTreatmentsToPerformSection(
              appointmentId: visit.appointmentId,
              onMarkPerformed: (String plannedTreatmentId) =>
                  _markPlannedTreatmentPerformed(
                    context,
                    ref,
                    visitId: visit.id,
                    plannedTreatmentId: plannedTreatmentId,
                  ),
            ),
          const Divider(height: 1),
          Expanded(
            child: treatmentsAsync.when(
              data: (List<PerformedTreatment> treatments) {
                if (treatments.isEmpty) {
                  return Center(child: Text(l10n.visitNoTreatmentsYet));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: treatments.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (BuildContext context, int index) {
                    final PerformedTreatment treatment = treatments[index];
                    return _TreatmentRow(
                      treatment: treatment,
                      onEdit: !canEditTreatments
                          ? null
                          : () => _showTreatmentFormDialog(
                              context,
                              ref,
                              visitId: visit.id,
                              initial: treatment,
                            ),
                      onRemove: !canEditTreatments
                          ? null
                          : () => _removeTreatment(context, ref, treatment.id),
                    );
                  },
                );
              },
              error: (Object error, StackTrace stackTrace) =>
                  Center(child: Text('$error')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTreatmentFormDialog(
    BuildContext context,
    WidgetRef ref, {
    required String visitId,
    PerformedTreatment? initial,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _TreatmentFormDialog(
          initial: initial,
          onSubmit: (_TreatmentFormResult result) {
            final PerformedTreatmentController controller = ref.read(
              performedTreatmentControllerProvider.notifier,
            );
            if (initial == null) {
              controller.add(
                visitId: visitId,
                toothNumber: result.toothNumber,
                procedureName: result.procedureName,
                unitPrice: result.unitPrice,
                quantity: result.quantity,
              );
            } else {
              controller.updateTreatment(
                treatmentId: initial.id,
                toothNumber: result.toothNumber,
                procedureName: result.procedureName,
                unitPrice: result.unitPrice,
                quantity: result.quantity,
              );
            }
          },
        );
      },
    );
  }

  Future<void> _removeTreatment(
    BuildContext context,
    WidgetRef ref,
    String treatmentId,
  ) async {
    await ref
        .read(performedTreatmentControllerProvider.notifier)
        .remove(treatmentId: treatmentId);

    final Object? error = ref.read(performedTreatmentControllerProvider).error;
    if (error is VisitNotEditableException) {
      if (!context.mounted) return;
      final AppLocalizations l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.visitNotEditableError)));
    }
  }

  Future<void> _markPlannedTreatmentPerformed(
    BuildContext context,
    WidgetRef ref, {
    required String visitId,
    required String plannedTreatmentId,
  }) async {
    await ref
        .read(performedTreatmentControllerProvider.notifier)
        .markPlannedTreatmentPerformed(
          visitId: visitId,
          plannedTreatmentId: plannedTreatmentId,
        );

    if (!context.mounted) return;
    final Object? error = ref.read(performedTreatmentControllerProvider).error;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    if (error is VisitNotEditableException) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.visitNotEditableError)));
    } else if (error is PlannedTreatmentNotScheduledException) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.visitPlannedTreatmentNotScheduledError)),
      );
    }
  }

  Future<void> _confirmCompleteVisit(
    BuildContext context,
    WidgetRef ref,
    String visitId,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.visitCompleteConfirmTitle),
          content: Text(l10n.visitCompleteConfirmMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.confirm),
            ),
          ],
        );
      },
    );
    if (!(confirmed ?? false)) return;

    await ref
        .read(visitControllerProvider.notifier)
        .completeVisit(visitId: visitId);

    if (!context.mounted) return;
    final Object? error = ref.read(visitControllerProvider).error;
    if (error is VisitNotEditableException) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.visitNotEditableError)));
    } else if (error is VisitRequiresTreatmentException) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.visitRequiresTreatmentError)));
    } else if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.visitCompletedInvoiceCreated)),
      );
    }
  }

  Future<void> _confirmUnlockVisit(
    BuildContext context,
    WidgetRef ref,
    String visitId,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String? reason = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => const _UnlockVisitDialog(),
    );
    if (reason == null) return;

    await ref
        .read(visitControllerProvider.notifier)
        .unlockVisit(visitId: visitId, reason: reason);

    if (!context.mounted) return;
    final Object? error = ref.read(visitControllerProvider).error;
    if (error is VisitInvoiceHasPaymentsException) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.visitUnlockInvoiceHasPaymentsError)),
      );
    } else if (error is VisitInvoiceFinalizedException) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.visitUnlockInvoiceFinalizedError)),
      );
    } else if (error is VisitNotEditableException) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.visitNotEditableError)));
    } else if (error == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.visitUnlockedMessage)));
    }
  }

  void _viewInvoice(BuildContext context, String visitId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => InvoiceDetailPage(visitId: visitId),
      ),
    );
  }
}
