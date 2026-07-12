part of '../inventory_list_page.dart';

class _RestockFormResult {
  const _RestockFormResult({
    required this.quantityAdded,
    required this.restockDate,
    this.supplier,
    this.notes,
  });

  final int quantityAdded;
  final DateTime restockDate;
  final String? supplier;
  final String? notes;
}

class _RestockFormDialog extends StatefulWidget {
  const _RestockFormDialog({required this.onSubmit});

  final void Function(_RestockFormResult result) onSubmit;

  @override
  State<_RestockFormDialog> createState() => _RestockFormDialogState();
}

class _RestockFormDialogState extends State<_RestockFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _restockDate = DateTime.now();

  @override
  void dispose() {
    _quantityController.dispose();
    _supplierController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickRestockDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _restockDate,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (picked != null) setState(() => _restockDate = picked);
  }

  void _submit(AppLocalizations l10n) {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    widget.onSubmit(
      _RestockFormResult(
        quantityAdded: int.parse(_quantityController.text.trim()),
        restockDate: _restockDate,
        supplier: _supplierController.text.trim().isEmpty
            ? null
            : _supplierController.text.trim(),
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
      title: Text(l10n.inventoryRestockButton),
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
                    labelText: l10n.inventoryQuantityAddedField,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.patientRequiredFieldError;
                    }
                    final int? parsed = int.tryParse(value.trim());
                    return parsed == null || parsed <= 0
                        ? l10n.inventoryInvalidQuantityAddedError
                        : null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                InkWell(
                  onTap: _pickRestockDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.inventoryRestockDateField,
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(_restockDate)),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _supplierController,
                  decoration: InputDecoration(
                    labelText: l10n.inventorySupplierField,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: l10n.inventoryRestockNotesField,
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
        FilledButton(onPressed: () => _submit(l10n), child: Text(l10n.save)),
      ],
    );
  }
}
