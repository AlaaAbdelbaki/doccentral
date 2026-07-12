part of '../day_closeout_page.dart';

class _ConfirmCloseoutDialog extends StatefulWidget {
  const _ConfirmCloseoutDialog({required this.onSubmit});

  final void Function(double countedCash) onSubmit;

  @override
  State<_ConfirmCloseoutDialog> createState() => _ConfirmCloseoutDialogState();
}

class _ConfirmCloseoutDialogState extends State<_ConfirmCloseoutDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _countedCashController = TextEditingController();

  @override
  void dispose() {
    _countedCashController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSubmit(double.parse(_countedCashController.text.trim()));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.dayCloseoutConfirmButton),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _countedCashController,
          decoration: InputDecoration(
            labelText: l10n.dayCloseoutCountedCashField,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (String? value) {
            final double? parsed = double.tryParse((value ?? '').trim());
            return parsed == null || parsed < 0
                ? l10n.dayCloseoutInvalidCountedCashError
                : null;
          },
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
