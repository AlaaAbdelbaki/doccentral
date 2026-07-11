part of '../visit_detail_page.dart';

class _TreatmentRow extends StatelessWidget {
  const _TreatmentRow({required this.treatment, this.onEdit, this.onRemove});

  final PerformedTreatment treatment;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    treatment.procedureName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    '${l10n.visitTreatmentToothNumberField}: ${treatment.toothNumber} '
                    '· ${treatment.quantity} × '
                    '${NumberFormat.currency(symbol: 'TND', decimalDigits: 3).format(treatment.unitPrice)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              NumberFormat.currency(
                symbol: 'TND',
                decimalDigits: 3,
              ).format(treatment.totalPrice),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (onEdit != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: l10n.visitEditTreatmentButton,
              ),
            ],
            if (onRemove != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.visitRemoveTreatmentButton,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
