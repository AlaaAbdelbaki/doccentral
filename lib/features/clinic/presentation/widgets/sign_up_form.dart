part of '../sign_up_page.dart';

class SignUpFormResult {
  const SignUpFormResult({
    required this.clinicName,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
  });

  final String clinicName;
  final String firstName;
  final String lastName;
  final String email;
  final String password;
}

class _SignUpForm extends StatefulWidget {
  const _SignUpForm({required this.isSubmitting, required this.onSubmit});

  final bool isSubmitting;
  final void Function(SignUpFormResult result) onSubmit;

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  static const int _minPasswordLength = 6;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _clinicNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _clinicNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    widget.onSubmit(
      SignUpFormResult(
        clinicName: _clinicNameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
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
          Text(
            l10n.signUpTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _clinicNameController,
            decoration: InputDecoration(labelText: l10n.signUpClinicName),
            validator: requiredValidator,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _firstNameController,
            decoration: InputDecoration(labelText: l10n.signUpFirstName),
            validator: requiredValidator,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _lastNameController,
            decoration: InputDecoration(labelText: l10n.signUpLastName),
            validator: requiredValidator,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(labelText: l10n.signUpEmail),
            keyboardType: TextInputType.emailAddress,
            validator: requiredValidator,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: l10n.signUpPassword),
            obscureText: true,
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return l10n.requiredFieldError;
              }
              if (value.length < _minPasswordLength) {
                return l10n.signUpPasswordTooShortError;
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(labelText: l10n.signUpConfirmPassword),
            obscureText: true,
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return l10n.requiredFieldError;
              }
              if (value != _passwordController.text) {
                return l10n.signUpPasswordMismatchError;
              }
              return null;
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
                : Text(l10n.signUpSubmitButton),
          ),
        ],
      ),
    );
  }
}
