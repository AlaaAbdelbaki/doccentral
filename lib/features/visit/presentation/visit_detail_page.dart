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
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

part 'widgets/clinical_record_section.dart';
part 'widgets/treatment_form_dialog.dart';
part 'widgets/treatment_row.dart';

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
    final AsyncValue<List<PerformedTreatment>> treatmentsAsync = ref.watch(
      performedTreatmentsProvider(visit.id),
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
}
