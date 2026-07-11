part of '../calendar_page.dart';

class _CancelReasonDialog extends StatelessWidget {
  const _CancelReasonDialog();

  static String _labelFor(AppLocalizations l10n, CancellationReason reason) {
    switch (reason) {
      case CancellationReason.patientCancelled:
        return l10n.cancellationReasonPatientCancelled;
      case CancellationReason.noShow:
        return l10n.cancellationReasonNoShow;
      case CancellationReason.clinicCancelled:
        return l10n.cancellationReasonClinicCancelled;
      case CancellationReason.rescheduled:
        return l10n.cancellationReasonRescheduled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return SimpleDialog(
      title: Text(l10n.appointmentCancelReasonTitle),
      children: <Widget>[
        for (final CancellationReason reason in CancellationReason.values)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(reason),
            child: Text(_labelFor(l10n, reason)),
          ),
      ],
    );
  }
}
