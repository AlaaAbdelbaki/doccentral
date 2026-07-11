part of '../invoice_detail_page.dart';

class _InvoiceItemRow extends StatelessWidget {
  const _InvoiceItemRow({required this.item});

  final InvoiceItem item;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final NumberFormat currency = NumberFormat.currency(
      symbol: 'TND',
      decimalDigits: 3,
    );
    final String subtitle = item.toothNumber == null
        ? '${item.quantity} × ${currency.format(item.unitPrice)}'
        : '${l10n.visitTreatmentToothNumberField}: ${item.toothNumber} '
              '· ${item.quantity} × ${currency.format(item.unitPrice)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        item.description,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (item.adjustmentType != null) ...<Widget>[
                        const SizedBox(width: AppSpacing.sm),
                        Chip(
                          label: Text(
                            item.adjustmentType ==
                                    InvoiceAdjustmentType.discount
                                ? l10n.invoiceAdjustmentTypeDiscount
                                : l10n.invoiceAdjustmentTypeSurcharge,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ],
                  ),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Text(
              currency.format(item.totalPrice),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}
