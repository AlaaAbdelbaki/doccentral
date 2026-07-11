part of '../visit_detail_page.dart';

class _UnlockVisitDialog extends StatefulWidget {
  const _UnlockVisitDialog();

  @override
  State<_UnlockVisitDialog> createState() => _UnlockVisitDialogState();
}

class _UnlockVisitDialogState extends State<_UnlockVisitDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_reasonController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.visitUnlockConfirmTitle),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _reasonController,
            decoration: InputDecoration(labelText: l10n.visitUnlockReasonField),
            maxLines: 3,
            validator: (String? value) =>
                (value == null || value.trim().isEmpty)
                ? l10n.visitUnlockReasonRequiredError
                : null,
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.confirm)),
      ],
    );
  }
}
