part of '../invoice_detail_page.dart';

class _AdjustmentFormResult {
  const _AdjustmentFormResult({
    required this.adjustmentType,
    required this.description,
    required this.amount,
  });

  final InvoiceAdjustmentType adjustmentType;
  final String description;
  final double amount;
}

class _AdjustmentFormDialog extends StatefulWidget {
  const _AdjustmentFormDialog({required this.onSubmit});

  final void Function(_AdjustmentFormResult result) onSubmit;

  @override
  State<_AdjustmentFormDialog> createState() => _AdjustmentFormDialogState();
}

class _AdjustmentFormDialogState extends State<_AdjustmentFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  InvoiceAdjustmentType _adjustmentType = InvoiceAdjustmentType.discount;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    widget.onSubmit(
      _AdjustmentFormResult(
        adjustmentType: _adjustmentType,
        description: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.invoiceAddAdjustmentButton),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DropdownButtonFormField<InvoiceAdjustmentType>(
                  initialValue: _adjustmentType,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.invoiceAdjustmentTypeField,
                  ),
                  items: <DropdownMenuItem<InvoiceAdjustmentType>>[
                    DropdownMenuItem<InvoiceAdjustmentType>(
                      value: InvoiceAdjustmentType.discount,
                      child: Text(l10n.invoiceAdjustmentTypeDiscount),
                    ),
                    DropdownMenuItem<InvoiceAdjustmentType>(
                      value: InvoiceAdjustmentType.surcharge,
                      child: Text(l10n.invoiceAdjustmentTypeSurcharge),
                    ),
                  ],
                  onChanged: (InvoiceAdjustmentType? value) {
                    if (value != null) setState(() => _adjustmentType = value);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: l10n.invoiceAdjustmentDescriptionField,
                  ),
                  validator: (String? value) =>
                      (value == null || value.trim().isEmpty)
                      ? l10n.patientRequiredFieldError
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: l10n.invoiceAdjustmentAmountField,
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
                        ? l10n.invoiceAdjustmentInvalidAmountError
                        : null;
                  },
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
