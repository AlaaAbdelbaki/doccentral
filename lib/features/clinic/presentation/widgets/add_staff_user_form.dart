part of '../add_staff_user_page.dart';

class AddStaffUserFormResult {
  const AddStaffUserFormResult({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.role,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final Role role;
}

class _AddStaffUserForm extends StatefulWidget {
  const _AddStaffUserForm({required this.isSubmitting, required this.onSubmit});

  final bool isSubmitting;
  final void Function(AddStaffUserFormResult result) onSubmit;

  @override
  State<_AddStaffUserForm> createState() => _AddStaffUserFormState();
}

class _AddStaffUserFormState extends State<_AddStaffUserForm> {
  static const int _minPasswordLength = 6;
  static const List<Role> _assignableRoles = <Role>[Role.assistant, Role.nurse];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  Role _role = Role.assistant;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    widget.onSubmit(
      AddStaffUserFormResult(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _role,
      ),
    );
  }

  String _roleLabel(AppLocalizations l10n, Role role) {
    switch (role) {
      case Role.assistant:
        return l10n.addStaffRoleAssistant;
      case Role.nurse:
        return l10n.addStaffRoleNurse;
      case Role.doctor:
        return l10n.addStaffRoleAssistant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    String? requiredValidator(String? value) =>
        (value == null || value.trim().isEmpty)
        ? l10n.requiredFieldError
        : null;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextFormField(
            controller: _firstNameController,
            decoration: InputDecoration(labelText: l10n.addStaffFirstName),
            validator: requiredValidator,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _lastNameController,
            decoration: InputDecoration(labelText: l10n.addStaffLastName),
            validator: requiredValidator,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(labelText: l10n.addStaffEmail),
            keyboardType: TextInputType.emailAddress,
            validator: requiredValidator,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: l10n.addStaffPassword),
            obscureText: true,
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return l10n.requiredFieldError;
              }
              if (value.length < _minPasswordLength) {
                return l10n.addStaffPasswordTooShortError;
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<Role>(
            initialValue: _role,
            decoration: InputDecoration(labelText: l10n.addStaffRole),
            items: <DropdownMenuItem<Role>>[
              for (final Role role in _assignableRoles)
                DropdownMenuItem<Role>(
                  value: role,
                  child: Text(_roleLabel(l10n, role)),
                ),
            ],
            onChanged: (Role? value) {
              if (value != null) setState(() => _role = value);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: widget.isSubmitting ? null : _submit,
            child: widget.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.addStaffSubmitButton),
          ),
        ],
      ),
    );
  }
}
