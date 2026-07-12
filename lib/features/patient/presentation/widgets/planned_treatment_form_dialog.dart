part of '../patient_list_page.dart';

class PlannedTreatmentFormResult {
  const PlannedTreatmentFormResult({
    required this.procedureName,
    required this.toothNumber,
    required this.estimatedUnitPrice,
    this.targetDate,
  });

  final String procedureName;
  final String toothNumber;
  final double estimatedUnitPrice;
  final DateTime? targetDate;
}

class _PlannedTreatmentFormDialog extends StatefulWidget {
  const _PlannedTreatmentFormDialog({required this.onSubmit});

  final void Function(PlannedTreatmentFormResult result) onSubmit;

  @override
  State<_PlannedTreatmentFormDialog> createState() =>
      _PlannedTreatmentFormDialogState();
}

class _PlannedTreatmentFormDialogState
    extends State<_PlannedTreatmentFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _procedureController = TextEditingController();
  final TextEditingController _toothNumberController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  DateTime? _targetDate;

  @override
  void dispose() {
    _procedureController.dispose();
    _toothNumberController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  Future<void> _pickTargetDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  void _submit(AppLocalizations l10n) {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    widget.onSubmit(
      PlannedTreatmentFormResult(
        procedureName: _procedureController.text.trim(),
        toothNumber: _toothNumberController.text.trim(),
        estimatedUnitPrice: double.parse(_unitPriceController.text.trim()),
        targetDate: _targetDate,
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
      title: Text(l10n.treatmentPlanAddButton),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _procedureController,
                  decoration: InputDecoration(
                    labelText: l10n.treatmentPlanProcedureField,
                  ),
                  validator: requiredValidator,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _toothNumberController,
                  decoration: InputDecoration(
                    labelText: l10n.treatmentPlanToothNumberField,
                  ),
                  validator: requiredValidator,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _unitPriceController,
                  decoration: InputDecoration(
                    labelText: l10n.treatmentPlanEstimatedPriceField,
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
                        ? l10n.treatmentPlanInvalidPriceError
                        : null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                InkWell(
                  onTap: _pickTargetDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.treatmentPlanTargetDateField,
                    ),
                    child: Text(
                      _targetDate == null
                          ? l10n.treatmentPlanNextAvailable
                          : DateFormat('dd/MM/yyyy').format(_targetDate!),
                    ),
                  ),
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
