import 'package:docentral/features/appointment/presentation/providers/no_show_pattern_provider.dart';
import 'package:docentral/features/attachment/domain/attachment_target_type.dart';
import 'package:docentral/features/invoice/presentation/providers/outstanding_balance_provider.dart';
import 'package:docentral/features/patient/domain/patient_record.dart';
import 'package:docentral/features/treatment_plan/domain/planned_treatment.dart';
import 'package:docentral/features/treatment_plan/domain/planned_treatment_status.dart';
import 'package:docentral/features/treatment_plan/presentation/providers/planned_treatment_controller_provider.dart';
import 'package:docentral/features/treatment_plan/presentation/providers/planned_treatments_provider.dart';
import 'package:docentral/features/visit/domain/visit_record.dart';
import 'package:docentral/features/visit/domain/visit_status.dart';
import 'package:docentral/features/visit/presentation/providers/recent_visits_provider.dart';
import 'package:docentral/features/patient/presentation/providers/patient_controller_provider.dart';
import 'package:docentral/features/patient/presentation/providers/patient_list_provider.dart';
import 'package:docentral/features/patient/presentation/providers/patient_search_query_provider.dart';
import 'package:docentral/features/patient/presentation/providers/selected_patient_provider.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/providers/permission_provider.dart';
import 'package:docentral/shared/data/router/app_routes.dart';
import 'package:docentral/shared/design_system/app_spacing.dart';
import 'package:docentral/shared/design_system/widgets/docentral_attachments_section.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

part 'widgets/patient_detail_pane.dart';
part 'widgets/patient_form_dialog.dart';
part 'widgets/patient_list_pane.dart';
part 'widgets/patient_row.dart';
part 'widgets/patient_search_bar.dart';
part 'widgets/patient_section_card.dart';
part 'widgets/planned_treatment_form_dialog.dart';
part 'widgets/planned_treatment_row.dart';

class PatientListPage extends ConsumerWidget {
  const PatientListPage({super.key});

  static const double _listPaneWidth = 340;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AsyncValue<List<PatientRecord>> patientsAsync = ref.watch(
      patientListProvider,
    );
    final PatientRecord? selected = ref.watch(selectedPatientProvider);
    final bool canCreate = ref.watch(permissionCheckerProvider)(
      Permission.canCreatePatient,
    );
    final bool canEdit = ref.watch(permissionCheckerProvider)(
      Permission.canEditPatient,
    );
    final bool canDelete = ref.watch(permissionCheckerProvider)(
      Permission.canDeletePatient,
    );
    final bool canViewFinances = ref.watch(permissionCheckerProvider)(
      Permission.canViewFinances,
    );
    final int patientCount = patientsAsync.value?.length ?? 0;
    final bool hasNoShowPattern = selected == null
        ? false
        : ref.watch(hasNoShowPatternProvider(selected.id)).value ?? false;
    final List<VisitRecord> recentVisits = selected == null
        ? const <VisitRecord>[]
        : ref.watch(recentVisitsProvider(selected.id)).value ??
              const <VisitRecord>[];
    final double outstandingBalance = selected == null
        ? 0
        : ref.watch(outstandingBalanceProvider(selected.id)).value ?? 0;
    final bool canManageTreatmentPlan = ref.watch(permissionCheckerProvider)(
      Permission.canManageTreatmentPlan,
    );
    final bool canManageAttachments = ref.watch(permissionCheckerProvider)(
      Permission.canManageAttachments,
    );
    final List<PlannedTreatment> plannedTreatments = selected == null
        ? const <PlannedTreatment>[]
        : ref.watch(plannedTreatmentsProvider(selected.id)).value ??
              const <PlannedTreatment>[];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.patientsPageTitle),
            Text(
              l10n.patientsSubtitle(patientCount),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          if (canViewFinances)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: IconButton(
                onPressed: () =>
                    context.goNamed(AppRoutes.patientsWithBalance.name),
                icon: const Icon(Icons.account_balance_wallet_outlined),
                tooltip: l10n.patientsWithBalanceButton,
              ),
            ),
          if (canCreate)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: FilledButton.icon(
                onPressed: () => _showAddPatientDialog(context, ref),
                icon: const Icon(Icons.add),
                label: Text(l10n.patientAddButton),
              ),
            ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _listPaneWidth,
            child: _PatientListPane(
              patientsAsync: patientsAsync,
              selectedId: selected?.id,
              onQueryChanged: (String value) =>
                  ref.read(patientSearchQueryProvider.notifier).setQuery(value),
              onSelect: (PatientRecord patient) =>
                  ref.read(selectedPatientProvider.notifier).select(patient),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _PatientDetailPane(
              patient: selected,
              canEdit: canEdit,
              onEdit: () {
                if (selected != null) {
                  _showEditPatientDialog(context, ref, selected);
                }
              },
              canDelete: canDelete,
              onDelete: () {
                if (selected != null) {
                  _confirmDeletePatient(context, ref, selected);
                }
              },
              hasNoShowPattern: hasNoShowPattern,
              recentVisits: recentVisits,
              outstandingBalance: outstandingBalance,
              plannedTreatments: plannedTreatments,
              canManageTreatmentPlan: canManageTreatmentPlan,
              onAddPlannedTreatment: () {
                if (selected != null) {
                  _showAddPlannedTreatmentDialog(context, ref, selected.id);
                }
              },
              canManageAttachments: canManageAttachments,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddPatientDialog(BuildContext context, WidgetRef ref) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _PatientFormDialog(
          onSubmit: (PatientFormResult result) {
            ref
                .read(patientControllerProvider.notifier)
                .create(
                  firstName: result.firstName,
                  lastName: result.lastName,
                  dateOfBirth: result.dateOfBirth,
                  phone: result.phone,
                  email: result.email,
                  historyNotes: result.historyNotes,
                );
          },
        );
      },
    );
  }

  Future<void> _showEditPatientDialog(
    BuildContext context,
    WidgetRef ref,
    PatientRecord patient,
  ) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _PatientFormDialog(
          initial: patient,
          onSubmit: (PatientFormResult result) {
            ref
                .read(patientControllerProvider.notifier)
                .updatePatient(
                  patientId: patient.id,
                  firstName: result.firstName,
                  lastName: result.lastName,
                  dateOfBirth: result.dateOfBirth,
                  phone: result.phone,
                  email: result.email,
                  historyNotes: result.historyNotes,
                );
          },
        );
      },
    );
  }

  Future<void> _confirmDeletePatient(
    BuildContext context,
    WidgetRef ref,
    PatientRecord patient,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.patientDeleteConfirmTitle),
          content: Text(
            l10n.patientDeleteConfirmMessage(
              '${patient.firstName} ${patient.lastName}',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );

    if (confirmed ?? false) {
      await ref
          .read(patientControllerProvider.notifier)
          .deletePatient(patientId: patient.id);
      ref.read(selectedPatientProvider.notifier).select(null);
    }
  }

  Future<void> _showAddPlannedTreatmentDialog(
    BuildContext context,
    WidgetRef ref,
    String patientId,
  ) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _PlannedTreatmentFormDialog(
          onSubmit: (PlannedTreatmentFormResult result) {
            ref
                .read(plannedTreatmentControllerProvider.notifier)
                .add(
                  patientId: patientId,
                  procedureName: result.procedureName,
                  toothNumber: result.toothNumber,
                  estimatedUnitPrice: result.estimatedUnitPrice,
                  targetDate: result.targetDate,
                );
          },
        );
      },
    );
  }
}
