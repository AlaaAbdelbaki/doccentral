part of '../inventory_list_page.dart';

class _InventoryItemFormResult {
  const _InventoryItemFormResult({
    required this.name,
    required this.category,
    required this.unit,
    required this.onHandQuantity,
    required this.lowStockThreshold,
  });

  final String name;
  final InventoryCategory category;
  final String unit;
  final int onHandQuantity;
  final int lowStockThreshold;
}

class _InventoryItemFormDialog extends StatefulWidget {
  const _InventoryItemFormDialog({required this.onSubmit});

  final void Function(_InventoryItemFormResult result) onSubmit;

  @override
  State<_InventoryItemFormDialog> createState() =>
      _InventoryItemFormDialogState();
}

class _InventoryItemFormDialogState extends State<_InventoryItemFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _onHandQuantityController =
      TextEditingController();
  final TextEditingController _lowStockThresholdController =
      TextEditingController();
  InventoryCategory _category = InventoryCategory.supply;

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _onHandQuantityController.dispose();
    _lowStockThresholdController.dispose();
    super.dispose();
  }

  void _submit(AppLocalizations l10n) {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    widget.onSubmit(
      _InventoryItemFormResult(
        name: _nameController.text.trim(),
        category: _category,
        unit: _unitController.text.trim(),
        onHandQuantity: int.parse(_onHandQuantityController.text.trim()),
        lowStockThreshold: int.parse(_lowStockThresholdController.text.trim()),
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

    return AlertDialog(
      title: Text(l10n.inventoryAddItemButton),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.inventoryNameField,
                  ),
                  validator: requiredValidator,
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<InventoryCategory>(
                  initialValue: _category,
                  decoration: InputDecoration(
                    labelText: l10n.inventoryCategoryField,
                  ),
                  items: <DropdownMenuItem<InventoryCategory>>[
                    for (final InventoryCategory category
                        in InventoryCategory.values)
                      DropdownMenuItem<InventoryCategory>(
                        value: category,
                        child: Text(
                          InventoryListPage._categoryLabel(l10n, category),
                        ),
                      ),
                  ],
                  onChanged: (InventoryCategory? category) {
                    if (category != null) {
                      setState(() => _category = category);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _unitController,
                  decoration: InputDecoration(
                    labelText: l10n.inventoryUnitField,
                  ),
                  validator: requiredValidator,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _onHandQuantityController,
                  decoration: InputDecoration(
                    labelText: l10n.inventoryOnHandQuantityField,
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
                  controller: _lowStockThresholdController,
                  decoration: InputDecoration(
                    labelText: l10n.inventoryLowStockThresholdField,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.patientRequiredFieldError;
                    }
                    final int? parsed = int.tryParse(value.trim());
                    return parsed == null || parsed < 0
                        ? l10n.inventoryNegativeThresholdError
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
        FilledButton(onPressed: () => _submit(l10n), child: Text(l10n.save)),
      ],
    );
  }
}
