part of '../patient_list_page.dart';

class PatientFormResult {
  const PatientFormResult({
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.phone,
    this.email,
    this.historyNotes,
  });

  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String phone;
  final String? email;
  final String? historyNotes;
}

class _PatientFormDialog extends StatefulWidget {
  const _PatientFormDialog({required this.onSubmit, this.initial});

  final void Function(PatientFormResult result) onSubmit;
  final PatientRecord? initial;

  @override
  State<_PatientFormDialog> createState() => _PatientFormDialogState();
}

class _PatientFormDialogState extends State<_PatientFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController = TextEditingController(
    text: widget.initial?.firstName,
  );
  late final TextEditingController _lastNameController = TextEditingController(
    text: widget.initial?.lastName,
  );
  late final TextEditingController _phoneController = TextEditingController(
    text: widget.initial?.phone,
  );
  late final TextEditingController _emailController = TextEditingController(
    text: widget.initial?.email,
  );
  late final TextEditingController _historyNotesController =
      TextEditingController(text: widget.initial?.historyNotes);
  late DateTime? _dateOfBirth = widget.initial?.dateOfBirth;
  String? _dateOfBirthError;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _historyNotesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        _dateOfBirthError = null;
      });
    }
  }

  void _submit(AppLocalizations l10n) {
    final bool formValid = _formKey.currentState?.validate() ?? false;
    final DateTime? dateOfBirth = _dateOfBirth;
    if (dateOfBirth == null) {
      setState(() => _dateOfBirthError = l10n.patientRequiredFieldError);
    }
    if (!formValid || dateOfBirth == null) return;

    widget.onSubmit(
      PatientFormResult(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dateOfBirth: dateOfBirth,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        historyNotes: _historyNotesController.text.trim().isEmpty
            ? null
            : _historyNotesController.text.trim(),
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
      title: Text(
        widget.initial == null
            ? l10n.patientFormTitle
            : l10n.patientEditFormTitle,
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(labelText: l10n.patientFirstName),
                  validator: requiredValidator,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(labelText: l10n.patientLastName),
                  validator: requiredValidator,
                ),
                const SizedBox(height: AppSpacing.sm),
                InkWell(
                  onTap: _pickDateOfBirth,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.patientDateOfBirth,
                      errorText: _dateOfBirthError,
                    ),
                    child: Text(
                      _dateOfBirth == null
                          ? ''
                          : DateFormat('dd/MM/yyyy').format(_dateOfBirth!),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: l10n.patientPhone),
                  keyboardType: TextInputType.phone,
                  validator: requiredValidator,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: l10n.patientEmail),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _historyNotesController,
                  decoration: InputDecoration(
                    labelText: l10n.patientHistoryNotes,
                  ),
                  maxLines: 4,
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
