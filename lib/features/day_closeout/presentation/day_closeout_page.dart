import 'package:docentral/features/day_closeout/domain/day_closeout_exceptions.dart';
import 'package:docentral/features/day_closeout/domain/day_closeout_record.dart';
import 'package:docentral/features/day_closeout/domain/day_closeout_summary.dart';
import 'package:docentral/features/day_closeout/presentation/providers/day_closeout_controller_provider.dart';
import 'package:docentral/features/day_closeout/presentation/providers/day_closeout_for_today_provider.dart';
import 'package:docentral/features/day_closeout/presentation/providers/day_closeout_summary_provider.dart';
import 'package:docentral/features/invoice/domain/payment_method.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/providers/permission_provider.dart';
import 'package:docentral/shared/design_system/app_spacing.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

part 'widgets/confirm_closeout_dialog.dart';
part 'widgets/reopen_closeout_dialog.dart';

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
    final AsyncValue<DayCloseoutRecord?> closeoutAsync = ref.watch(
      dayCloseoutForTodayProvider,
    );
    final bool canConfirm = ref.watch(permissionCheckerProvider)(
      Permission.canConfirmDayCloseout,
    );
    final bool canReopen = ref.watch(permissionCheckerProvider)(
      Permission.canReopenDayCloseout,
    );
    final DayCloseoutRecord? closeout = closeoutAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navDayCloseout),
        actions: <Widget>[
          if (canConfirm && (closeout == null || closeout.isReopened))
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: FilledButton(
                onPressed: () => _showConfirmDialog(context, ref),
                child: Text(l10n.dayCloseoutConfirmButton),
              ),
            ),
          if (canReopen && closeout != null && !closeout.isReopened)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: OutlinedButton(
                onPressed: () => _showReopenDialog(context, ref, closeout.id),
                child: Text(l10n.dayCloseoutReopenButton),
              ),
            ),
        ],
      ),
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
            if (closeout != null) ...<Widget>[
              const Divider(height: AppSpacing.xl),
              Text(
                l10n.dayCloseoutRecordSection,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              _SummaryTile(
                label: l10n.dayCloseoutExpectedCashLabel,
                value: currency.format(closeout.expectedCash),
              ),
              _SummaryTile(
                label: l10n.dayCloseoutCountedCashLabel,
                value: currency.format(closeout.countedCash),
              ),
              _SummaryTile(
                label: l10n.dayCloseoutDeltaLabel,
                value: currency.format(closeout.delta),
                emphasize: true,
                warn: closeout.delta != 0,
              ),
            ],
          ],
        ),
        error: (Object error, StackTrace stackTrace) =>
            Center(child: Text('$error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _showConfirmDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _ConfirmCloseoutDialog(
          onSubmit: (double countedCash) {
            ref
                .read(dayCloseoutControllerProvider.notifier)
                .confirmCloseout(day: DateTime.now(), countedCash: countedCash);
          },
        );
      },
    );

    if (!context.mounted) return;
    final Object? error = ref.read(dayCloseoutControllerProvider).error;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    if (error is DayCloseoutAlreadyExistsException) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.dayCloseoutAlreadyClosedMessage)),
      );
    } else if (error == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.dayCloseoutConfirmedMessage)));
    }
  }

  Future<void> _showReopenDialog(
    BuildContext context,
    WidgetRef ref,
    String dayCloseoutId,
  ) async {
    final String? reason = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => const _ReopenCloseoutDialog(),
    );
    if (reason == null) return;

    await ref
        .read(dayCloseoutControllerProvider.notifier)
        .reopenCloseout(dayCloseoutId: dayCloseoutId, reason: reason);

    if (!context.mounted) return;
    final Object? error = ref.read(dayCloseoutControllerProvider).error;
    if (error == null) {
      final AppLocalizations l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.dayCloseoutReopenedMessage)));
    }
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.warn = false,
  });

  final String label;
  final String value;
  final bool emphasize;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    TextStyle? style = emphasize
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    if (warn) style = style?.copyWith(color: Colors.orange);
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
