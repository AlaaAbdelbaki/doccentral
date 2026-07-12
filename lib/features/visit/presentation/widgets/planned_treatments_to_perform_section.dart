part of '../visit_detail_page.dart';

class _PlannedTreatmentsToPerformSection extends StatelessWidget {
  const _PlannedTreatmentsToPerformSection({
    required this.appointmentId,
    required this.onMarkPerformed,
  });

  final String appointmentId;
  final void Function(String plannedTreatmentId) onMarkPerformed;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, _) {
        final List<PlannedTreatment> scheduled =
            (ref.watch(linkedPlannedTreatmentsProvider(appointmentId)).value ??
                    const <PlannedTreatment>[])
                .where(
                  (PlannedTreatment t) =>
                      t.status == PlannedTreatmentStatus.scheduled,
                )
                .toList();
        if (scheduled.isEmpty) return const SizedBox.shrink();

        final AppLocalizations l10n = AppLocalizations.of(context)!;
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.visitPlannedTreatmentsSection,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final PlannedTreatment treatment in scheduled)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '${treatment.procedureName} '
                          '(${l10n.treatmentPlanToothNumberField}: ${treatment.toothNumber})',
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => onMarkPerformed(treatment.id),
                        child: Text(l10n.visitMarkPerformedButton),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
