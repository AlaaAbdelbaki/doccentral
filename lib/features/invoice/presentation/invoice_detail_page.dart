import 'package:docentral/features/invoice/domain/invoice_adjustment_type.dart';
import 'package:docentral/features/invoice/domain/invoice_exceptions.dart';
import 'package:docentral/features/invoice/domain/invoice_item.dart';
import 'package:docentral/features/invoice/domain/invoice_record.dart';
import 'package:docentral/features/invoice/domain/invoice_status.dart';
import 'package:docentral/features/invoice/domain/payment.dart';
import 'package:docentral/features/invoice/domain/payment_exceptions.dart';
import 'package:docentral/features/invoice/domain/payment_method.dart';
import 'package:docentral/features/invoice/presentation/providers/invoice_controller_provider.dart';
import 'package:docentral/features/invoice/presentation/providers/invoice_for_visit_provider.dart';
import 'package:docentral/features/invoice/presentation/providers/invoice_items_provider.dart';
import 'package:docentral/features/invoice/presentation/providers/payment_controller_provider.dart';
import 'package:docentral/features/invoice/presentation/providers/payments_for_invoice_provider.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/providers/permission_provider.dart';
import 'package:docentral/shared/design_system/app_spacing.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

part 'widgets/adjustment_form_dialog.dart';
part 'widgets/invoice_item_row.dart';
part 'widgets/payment_form_dialog.dart';
part 'widgets/payment_row.dart';

class InvoiceDetailPage extends ConsumerWidget {
  const InvoiceDetailPage({super.key, required this.visitId});

  final String visitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final InvoiceRecord? invoice = ref
        .watch(invoiceForVisitProvider(visitId))
        .value;

    if (invoice == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.invoiceDetailPageTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final bool canEditInvoice = ref.watch(permissionCheckerProvider)(
      Permission.canEditInvoice,
    );
    final bool isDraft = invoice.status == InvoiceStatus.draft;
    final bool canAddAdjustment = canEditInvoice && isDraft;
    final bool canFinalize = canEditInvoice && isDraft;
    final bool canRecordPayment =
        ref.watch(permissionCheckerProvider)(Permission.canRecordPayment) &&
        invoice.status != InvoiceStatus.voided;
    final AsyncValue<List<InvoiceItem>> itemsAsync = ref.watch(
      invoiceItemsProvider(invoice.id),
    );
    final AsyncValue<List<Payment>> paymentsAsync = ref.watch(
      paymentsForInvoiceProvider(invoice.id),
    );
    final NumberFormat currency = NumberFormat.currency(
      symbol: 'TND',
      decimalDigits: 3,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.invoiceDetailPageTitle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${l10n.invoiceTotalLabel}: ${currency.format(invoice.totalAmount)} · '
                  '${_statusLabel(l10n, invoice.status)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (canAddAdjustment ||
                    canFinalize ||
                    canRecordPayment) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      if (canAddAdjustment)
                        FilledButton.icon(
                          onPressed: () => _showAdjustmentFormDialog(
                            context,
                            ref,
                            l10n,
                            invoice.id,
                          ),
                          icon: const Icon(Icons.add),
                          label: Text(l10n.invoiceAddAdjustmentButton),
                        ),
                      if (canFinalize)
                        OutlinedButton.icon(
                          onPressed: () => _confirmFinalizeInvoice(
                            context,
                            ref,
                            l10n,
                            invoice.id,
                          ),
                          icon: const Icon(Icons.lock_outline),
                          label: Text(l10n.invoiceFinalizeButton),
                        ),
                      if (canRecordPayment)
                        FilledButton.icon(
                          onPressed: () => _showPaymentFormDialog(
                            context,
                            ref,
                            l10n,
                            invoice.id,
                          ),
                          icon: const Icon(Icons.payments_outlined),
                          label: Text(l10n.invoiceRecordPaymentButton),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: itemsAsync.when(
              data: (List<InvoiceItem> items) {
                if (items.isEmpty) {
                  return Center(child: Text(l10n.invoiceNoItemsYet));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: items.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (BuildContext context, int index) =>
                      _InvoiceItemRow(item: items[index]),
                );
              },
              error: (Object error, StackTrace stackTrace) =>
                  Center(child: Text('$error')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              l10n.invoicePaymentsSection,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          SizedBox(
            height: 180,
            child: paymentsAsync.when(
              data: (List<Payment> payments) {
                if (payments.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(l10n.invoiceNoPaymentsYet),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: payments.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (BuildContext context, int index) =>
                      _PaymentRow(payment: payments[index]),
                );
              },
              error: (Object error, StackTrace stackTrace) =>
                  Center(child: Text('$error')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return l10n.invoiceStatusDraft;
      case InvoiceStatus.unpaid:
        return l10n.invoiceStatusUnpaid;
      case InvoiceStatus.partiallyPaid:
        return l10n.invoiceStatusPartiallyPaid;
      case InvoiceStatus.paid:
        return l10n.invoiceStatusPaid;
      case InvoiceStatus.voided:
        return l10n.invoiceStatusVoided;
    }
  }

  Future<void> _showAdjustmentFormDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String invoiceId,
  ) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _AdjustmentFormDialog(
          onSubmit: (_AdjustmentFormResult result) async {
            await ref
                .read(invoiceControllerProvider.notifier)
                .addAdjustment(
                  invoiceId: invoiceId,
                  adjustmentType: result.adjustmentType,
                  description: result.description,
                  amount: result.amount,
                );

            if (!context.mounted) return;
            final Object? error = ref.read(invoiceControllerProvider).error;
            if (error is InvoiceNotDraftException) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.invoiceNotDraftError)),
              );
            } else if (error is InvoiceAdjustmentValidationException) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.invoiceAdjustmentInvalidAmountError),
                ),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _confirmFinalizeInvoice(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String invoiceId,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.invoiceFinalizeConfirmTitle),
          content: Text(l10n.invoiceFinalizeConfirmMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.confirm),
            ),
          ],
        );
      },
    );
    if (!(confirmed ?? false)) return;

    await ref
        .read(invoiceControllerProvider.notifier)
        .finalizeInvoice(invoiceId: invoiceId);

    if (!context.mounted) return;
    final Object? error = ref.read(invoiceControllerProvider).error;
    if (error is InvoiceNotDraftException) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.invoiceNotDraftError)));
    } else if (error == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.invoiceFinalizedMessage)));
    }
  }

  Future<void> _showPaymentFormDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String invoiceId,
  ) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _PaymentFormDialog(
          onSubmit: (_PaymentFormResult result) async {
            await ref
                .read(paymentControllerProvider.notifier)
                .recordPayment(
                  invoiceId: invoiceId,
                  amount: result.amount,
                  method: result.method,
                  paymentDate: result.paymentDate,
                  notes: result.notes,
                );

            if (!context.mounted) return;
            final Object? error = ref.read(paymentControllerProvider).error;
            if (error is PaymentInvoiceVoidedException) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.invoiceVoidedError)));
            } else if (error is PaymentValidationException) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.invoicePaymentInvalidAmountError)),
              );
            } else if (error == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.invoicePaymentRecordedMessage)),
              );
            }
          },
        );
      },
    );
  }
}
