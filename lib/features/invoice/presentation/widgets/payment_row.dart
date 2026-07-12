part of '../invoice_detail_page.dart';

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});

  final Payment payment;

  String _methodLabel(AppLocalizations l10n, PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return l10n.invoicePaymentMethodCash;
      case PaymentMethod.card:
        return l10n.invoicePaymentMethodCard;
      case PaymentMethod.bankTransfer:
        return l10n.invoicePaymentMethodBankTransfer;
      case PaymentMethod.other:
        return l10n.invoicePaymentMethodOther;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final NumberFormat currency = NumberFormat.currency(
      symbol: 'TND',
      decimalDigits: 3,
    );
    final DateFormat dateFormat = DateFormat.yMMMd();

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
                    '${_methodLabel(l10n, payment.method)} · '
                    '${dateFormat.format(payment.paymentDate)}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (payment.notes != null && payment.notes!.isNotEmpty)
                    Text(
                      payment.notes!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            Text(
              currency.format(payment.amount),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}
