part of '../patient_list_page.dart';

class _PatientDetailPane extends StatelessWidget {
  const _PatientDetailPane({required this.patient});

  final PatientRecord? patient;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final PatientRecord? p = patient;

    if (p == null) {
      return Center(child: Text(l10n.patientSelectPrompt));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 28,
                child: Text(_PatientRow.initials(p.firstName, p.lastName)),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${p.firstName} ${p.lastName}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(DateFormat('dd/MM/yyyy').format(p.dateOfBirth)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionCard(
            title: l10n.patientOverviewSection,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('${l10n.patientPhone}: ${p.phone}'),
                if ((p.email ?? '').isNotEmpty)
                  Text('${l10n.patientEmail}: ${p.email}'),
              ],
            ),
          ),
          if ((p.historyNotes ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: l10n.patientHistoryNotes,
              child: Text(p.historyNotes!),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: l10n.patientRecentVisitsSection,
            child: Text(l10n.patientNoVisitsYet),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: l10n.patientTreatmentPlanSection,
            child: Text(l10n.patientNoTreatmentPlanYet),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: l10n.patientOutstandingBalanceSection,
            // No Invoice/Payment data exists yet (Epic 7) — this is a genuine
            // zero, not a stubbed placeholder value.
            child: Text(
              NumberFormat.currency(symbol: 'TND', decimalDigits: 3).format(0),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: l10n.patientAttachmentsSection,
            child: Text(l10n.patientNoAttachmentsYet),
          ),
        ],
      ),
    );
  }
}
