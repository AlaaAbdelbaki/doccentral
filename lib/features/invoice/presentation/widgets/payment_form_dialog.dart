part of '../invoice_detail_page.dart';

class _PaymentFormResult {
  const _PaymentFormResult({
    required this.amount,
    required this.method,
    required this.paymentDate,
    required this.notes,
  });

  final double amount;
  final PaymentMethod method;
  final DateTime paymentDate;
  final String? notes;
}

class _PaymentFormDialog extends StatefulWidget {
  const _PaymentFormDialog({required this.onSubmit});

  final void Function(_PaymentFormResult result) onSubmit;

  @override
  State<_PaymentFormDialog> createState() => _PaymentFormDialogState();
}

class _PaymentFormDialogState extends State<_PaymentFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;
  DateTime _paymentDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPaymentDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _paymentDate = picked);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    widget.onSubmit(
      _PaymentFormResult(
        amount: double.parse(_amountController.text.trim()),
        method: _method,
        paymentDate: _paymentDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.invoiceRecordPaymentButton),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: l10n.invoicePaymentAmountField,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.patientRequiredFieldError;
                    }
                    final double? parsed = double.tryParse(value.trim());
                    return parsed == null || parsed <= 0
                        ? l10n.invoicePaymentInvalidAmountError
                        : null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<PaymentMethod>(
                  initialValue: _method,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.invoicePaymentMethodField,
                  ),
                  items: <DropdownMenuItem<PaymentMethod>>[
                    DropdownMenuItem<PaymentMethod>(
                      value: PaymentMethod.cash,
                      child: Text(l10n.invoicePaymentMethodCash),
                    ),
                    DropdownMenuItem<PaymentMethod>(
                      value: PaymentMethod.card,
                      child: Text(l10n.invoicePaymentMethodCard),
                    ),
                    DropdownMenuItem<PaymentMethod>(
                      value: PaymentMethod.bankTransfer,
                      child: Text(l10n.invoicePaymentMethodBankTransfer),
                    ),
                    DropdownMenuItem<PaymentMethod>(
                      value: PaymentMethod.other,
                      child: Text(l10n.invoicePaymentMethodOther),
                    ),
                  ],
                  onChanged: (PaymentMethod? value) {
                    if (value != null) setState(() => _method = value);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                InkWell(
                  onTap: _pickPaymentDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.invoicePaymentDateField,
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(_paymentDate)),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: l10n.invoicePaymentNotesField,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
