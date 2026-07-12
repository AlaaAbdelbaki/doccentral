part of '../patient_list_page.dart';

class _PlannedTreatmentRow extends StatelessWidget {
  const _PlannedTreatmentRow({required this.treatment});

  final PlannedTreatment treatment;

  static String _statusLabel(
    AppLocalizations l10n,
    PlannedTreatmentStatus status,
  ) {
    switch (status) {
      case PlannedTreatmentStatus.planned:
        return l10n.treatmentPlanStatusPlanned;
      case PlannedTreatmentStatus.scheduled:
        return l10n.treatmentPlanStatusScheduled;
      case PlannedTreatmentStatus.inProgress:
        return l10n.treatmentPlanStatusInProgress;
      case PlannedTreatmentStatus.done:
        return l10n.treatmentPlanStatusDone;
      case PlannedTreatmentStatus.cancelled:
        return l10n.treatmentPlanStatusCancelled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String targetDateLabel = treatment.targetDate == null
        ? l10n.treatmentPlanNextAvailable
        : DateFormat('dd/MM/yyyy').format(treatment.targetDate!);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '${treatment.sequenceNumber}. ${treatment.procedureName} '
              '(${l10n.treatmentPlanToothNumberField}: ${treatment.toothNumber}) '
              '— $targetDateLabel',
            ),
          ),
          Text(_statusLabel(l10n, treatment.status)),
        ],
      ),
    );
  }
}
