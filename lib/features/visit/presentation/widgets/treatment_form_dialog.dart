part of '../visit_detail_page.dart';

class _TreatmentFormResult {
  const _TreatmentFormResult({
    required this.toothNumber,
    required this.procedureName,
    required this.unitPrice,
    required this.quantity,
  });

  final String toothNumber;
  final String procedureName;
  final double unitPrice;
  final int quantity;
}

class _TreatmentFormDialog extends StatefulWidget {
  const _TreatmentFormDialog({required this.onSubmit, this.initial});

  final void Function(_TreatmentFormResult result) onSubmit;
  final PerformedTreatment? initial;

  @override
  State<_TreatmentFormDialog> createState() => _TreatmentFormDialogState();
}

class _TreatmentFormDialogState extends State<_TreatmentFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _toothNumberController =
      TextEditingController(text: widget.initial?.toothNumber);
  late final TextEditingController _procedureController = TextEditingController(
    text: widget.initial?.procedureName,
  );
  late final TextEditingController _unitPriceController = TextEditingController(
    text: widget.initial?.unitPrice.toString(),
  );
  late final TextEditingController _quantityController = TextEditingController(
    text: widget.initial?.quantity.toString() ?? '1',
  );

  @override
  void dispose() {
    _toothNumberController.dispose();
    _procedureController.dispose();
    _unitPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _submit(AppLocalizations l10n) {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    widget.onSubmit(
      _TreatmentFormResult(
        toothNumber: _toothNumberController.text.trim(),
        procedureName: _procedureController.text.trim(),
        unitPrice: double.parse(_unitPriceController.text.trim()),
        quantity: int.parse(_quantityController.text.trim()),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    String? requiredValidator(String? value) =>
        (value == null || value.trim().isEmpty)
        ? l10n.patientRequiredFieldError
        : null;
    String? numberValidator(String? value) {
      if (value == null || value.trim().isEmpty) {
        return l10n.patientRequiredFieldError;
      }
      return double.tryParse(value.trim()) == null
          ? l10n.visitTreatmentInvalidNumberError
          : null;
    }

    String? quantityValidator(String? value) {
      if (value == null || value.trim().isEmpty) {
        return l10n.patientRequiredFieldError;
      }
      final int? parsed = int.tryParse(value.trim());
      return parsed == null || parsed < 1
          ? l10n.visitTreatmentInvalidNumberError
          : null;
    }

    return AlertDialog(
      title: Text(
        widget.initial == null
            ? l10n.visitTreatmentFormTitle
            : l10n.visitEditTreatmentFormTitle,
      ),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _toothNumberController,
                  decoration: InputDecoration(
                    labelText: l10n.visitTreatmentToothNumberField,
                  ),
                  validator: requiredValidator,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _procedureController,
                  decoration: InputDecoration(
                    labelText: l10n.visitTreatmentProcedureField,
                  ),
                  validator: requiredValidator,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _unitPriceController,
                  decoration: InputDecoration(
                    labelText: l10n.visitTreatmentUnitPriceField,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: numberValidator,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: l10n.visitTreatmentQuantityField,
                  ),
                  keyboardType: TextInputType.number,
                  validator: quantityValidator,
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
        FilledButton(onPressed: () => _submit(l10n), child: Text(l10n.save)),
      ],
    );
  }
}
