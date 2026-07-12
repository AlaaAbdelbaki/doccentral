part of '../inventory_list_page.dart';

class _AdjustmentFormResult {
  const _AdjustmentFormResult({
    required this.newQuantity,
    required this.reason,
  });

  final int newQuantity;
  final String reason;
}

class _AdjustmentFormDialog extends StatefulWidget {
  const _AdjustmentFormDialog({
    required this.currentQuantity,
    required this.onSubmit,
  });

  final int currentQuantity;
  final void Function(_AdjustmentFormResult result) onSubmit;

  @override
  State<_AdjustmentFormDialog> createState() => _AdjustmentFormDialogState();
}

class _AdjustmentFormDialogState extends State<_AdjustmentFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController = TextEditingController(
    text: '${widget.currentQuantity}',
  );
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submit(AppLocalizations l10n) {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    widget.onSubmit(
      _AdjustmentFormResult(
        newQuantity: int.parse(_quantityController.text.trim()),
        reason: _reasonController.text.trim(),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.inventoryAdjustStockButton),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: l10n.inventoryNewQuantityField,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.patientRequiredFieldError;
                    }
                    final int? parsed = int.tryParse(value.trim());
                    return parsed == null || parsed < 0
                        ? l10n.inventoryNegativeQuantityError
                        : null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: l10n.inventoryAdjustmentReasonField,
                  ),
                  validator: (String? value) =>
                      (value == null || value.trim().isEmpty)
                      ? l10n.patientRequiredFieldError
                      : null,
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
