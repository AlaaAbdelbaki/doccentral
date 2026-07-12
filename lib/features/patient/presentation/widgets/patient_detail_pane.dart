part of '../patient_list_page.dart';

class _PatientDetailPane extends StatelessWidget {
  const _PatientDetailPane({
    required this.patient,
    required this.canEdit,
    required this.onEdit,
    required this.canDelete,
    required this.onDelete,
    required this.hasNoShowPattern,
    required this.recentVisits,
    required this.outstandingBalance,
    required this.plannedTreatments,
    required this.canManageTreatmentPlan,
    required this.onAddPlannedTreatment,
    required this.canManageAttachments,
  });

  final PatientRecord? patient;
  final bool canEdit;
  final VoidCallback onEdit;
  final bool canDelete;
  final VoidCallback onDelete;
  final bool hasNoShowPattern;
  final List<VisitRecord> recentVisits;
  final double outstandingBalance;
  final List<PlannedTreatment> plannedTreatments;
  final bool canManageTreatmentPlan;
  final VoidCallback onAddPlannedTreatment;
  final bool canManageAttachments;

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${p.firstName} ${p.lastName}',
                      style: Theme.of(context).textTheme.headlineSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(DateFormat('dd/MM/yyyy').format(p.dateOfBirth)),
                  ],
                ),
              ),
              if (canEdit)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l10n.patientEditButton,
                ),
              if (canDelete)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.patientDeleteButton,
                ),
            ],
          ),
          if (hasNoShowPattern) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.xs),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.warning_amber_outlined,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.patientNoShowPatternWarning,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            child: recentVisits.isEmpty
                ? Text(l10n.patientNoVisitsYet)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (final VisitRecord visit in recentVisits)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Text(
                            '${DateFormat('dd/MM/yyyy HH:mm').format(visit.startedAt)} '
                            '— ${_visitStatusLabel(l10n, visit.status)}',
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: l10n.patientTreatmentPlanSection,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (plannedTreatments.isEmpty)
                  Text(l10n.patientNoTreatmentPlanYet)
                else
                  for (final PlannedTreatment treatment in plannedTreatments)
                    _PlannedTreatmentRow(treatment: treatment),
                if (canManageTreatmentPlan) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: onAddPlannedTreatment,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.treatmentPlanAddButton),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: l10n.patientOutstandingBalanceSection,
            child: Text(
              NumberFormat.currency(
                symbol: 'TND',
                decimalDigits: 3,
              ).format(outstandingBalance),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: DocCentralAttachmentsSection(
                title: l10n.patientAttachmentsSection,
                targetType: AttachmentTargetType.patient,
                targetId: p.id,
                canManage: canManageAttachments,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _visitStatusLabel(AppLocalizations l10n, VisitStatus status) {
    switch (status) {
      case VisitStatus.checkedIn:
        return l10n.visitStatusCheckedIn;
      case VisitStatus.inProgress:
        return l10n.visitStatusInProgress;
      case VisitStatus.completed:
        return l10n.visitStatusCompleted;
      case VisitStatus.billed:
        return l10n.visitStatusBilled;
    }
  }
}
