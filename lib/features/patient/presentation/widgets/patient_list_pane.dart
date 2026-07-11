part of '../patient_list_page.dart';

class _PatientListPane extends StatelessWidget {
  const _PatientListPane({
    required this.patientsAsync,
    required this.selectedId,
    required this.onQueryChanged,
    required this.onSelect,
  });

  final AsyncValue<List<PatientRecord>> patientsAsync;
  final String? selectedId;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<PatientRecord> onSelect;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: _PatientSearchBar(onChanged: onQueryChanged),
        ),
        Expanded(
          child: patientsAsync.when(
            data: (List<PatientRecord> patients) {
              if (patients.isEmpty) {
                return Center(child: Text(l10n.patientEmptyList));
              }
              return ListView.builder(
                itemCount: patients.length,
                itemBuilder: (BuildContext context, int index) {
                  final PatientRecord patient = patients[index];
                  return _PatientRow(
                    patient: patient,
                    selected: patient.id == selectedId,
                    onTap: () => onSelect(patient),
                  );
                },
              );
            },
            error: (Object error, StackTrace stackTrace) =>
                Center(child: Text(l10n.errorGeneric)),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }
}
