import 'package:docentral/features/patient/domain/patient_record.dart';
import 'package:docentral/features/patient/presentation/providers/patient_controller_provider.dart';
import 'package:docentral/features/patient/presentation/providers/patient_list_provider.dart';
import 'package:docentral/features/patient/presentation/providers/patient_search_query_provider.dart';
import 'package:docentral/features/patient/presentation/providers/selected_patient_provider.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/providers/permission_provider.dart';
import 'package:docentral/shared/design_system/app_spacing.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

part 'widgets/patient_detail_pane.dart';
part 'widgets/patient_form_dialog.dart';
part 'widgets/patient_list_pane.dart';
part 'widgets/patient_row.dart';
part 'widgets/patient_search_bar.dart';
part 'widgets/patient_section_card.dart';

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
    final int patientCount = patientsAsync.value?.length ?? 0;

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
}
