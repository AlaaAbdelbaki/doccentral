import 'package:docentral/features/day_closeout/domain/day_closeout_summary.dart';
import 'package:docentral/features/day_closeout/presentation/providers/day_closeout_summary_provider.dart';
import 'package:docentral/features/invoice/domain/payment_method.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/providers/permission_provider.dart';
import 'package:docentral/shared/design_system/app_spacing.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DayCloseoutPage extends ConsumerWidget {
  const DayCloseoutPage({super.key});

  static String _methodLabel(AppLocalizations l10n, PaymentMethod method) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool canView = ref.watch(permissionCheckerProvider)(
      Permission.canViewDayCloseout,
    );
    final NumberFormat currency = NumberFormat.currency(
      symbol: 'TND',
      decimalDigits: 3,
    );

    if (!canView) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.navDayCloseout)),
        body: Center(child: Text(l10n.dayCloseoutPermissionDeniedMessage)),
      );
    }

    final AsyncValue<DayCloseoutSummary> summaryAsync = ref.watch(
      dayCloseoutSummaryProvider,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navDayCloseout)),
      body: summaryAsync.when(
        data: (DayCloseoutSummary summary) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            _SummaryTile(
              label: l10n.dayCloseoutCompletedVisits,
              value: '${summary.completedVisitsCount}',
            ),
            _SummaryTile(
              label: l10n.dayCloseoutNewInvoicesTotal,
              value: currency.format(summary.newInvoicesTotal),
            ),
            _SummaryTile(
              label: l10n.dayCloseoutOutstandingInvoices,
              value: '${summary.outstandingInvoicesCount}',
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.dayCloseoutPaymentsByMethod,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (summary.paymentTotalsByMethod.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(l10n.dayCloseoutNoPaymentsYet),
              )
            else
              for (final MapEntry<PaymentMethod, double> entry
                  in summary.paymentTotalsByMethod.entries)
                _SummaryTile(
                  label: _methodLabel(l10n, entry.key),
                  value: currency.format(entry.value),
                ),
            const Divider(height: AppSpacing.xl),
            _SummaryTile(
              label: l10n.dayCloseoutTotalPayments,
              value: currency.format(summary.totalPayments),
              emphasize: true,
            ),
          ],
        ),
        error: (Object error, StackTrace stackTrace) =>
            Center(child: Text('$error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = emphasize
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
