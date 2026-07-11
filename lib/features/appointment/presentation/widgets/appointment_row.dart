part of '../calendar_page.dart';

class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({
    required this.appointment,
    this.onEdit,
    this.onCancel,
    this.onCheckIn,
    this.onViewPatientFile,
    this.visitStatus,
    this.onStartVisit,
    this.onViewVisit,
  });

  final AppointmentRecord appointment;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final VoidCallback? onCheckIn;
  final VoidCallback? onViewPatientFile;
  final VisitStatus? visitStatus;
  final VoidCallback? onStartVisit;
  final VoidCallback? onViewVisit;

  // No Invoice/Payment data exists yet (Epic 7) — every patient's balance is
  // a genuine zero, so the "if applicable" indicator never renders yet.
  static const double _outstandingBalance = 0;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String reason = (appointment.reason ?? '').trim().isEmpty
        ? l10n.appointmentNoReasonNoted
        : appointment.reason!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: 64,
                  child: Text(
                    DateFormat('HH:mm').format(appointment.startTime),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        appointment.patientName,
                        style: Theme.of(context).textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        reason,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (_outstandingBalance > 0)
                  Text(
                    NumberFormat.currency(
                      symbol: 'TND',
                      decimalDigits: 3,
                    ).format(_outstandingBalance),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.xs,
              children: <Widget>[
                _StatusBadge(status: appointment.status),
                if (visitStatus == VisitStatus.inProgress)
                  Text(
                    l10n.visitStatusInProgress,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: l10n.appointmentEditButton,
                  ),
                if (onCancel != null)
                  IconButton(
                    onPressed: onCancel,
                    icon: const Icon(Icons.event_busy_outlined),
                    tooltip: l10n.appointmentCancelButton,
                  ),
                if (onCheckIn != null)
                  IconButton(
                    onPressed: onCheckIn,
                    icon: const Icon(Icons.how_to_reg_outlined),
                    tooltip: l10n.appointmentCheckInButton,
                  ),
                if (onStartVisit != null)
                  IconButton(
                    onPressed: onStartVisit,
                    icon: const Icon(Icons.play_circle_outline),
                    tooltip: l10n.appointmentStartVisitButton,
                  ),
                if (onViewVisit != null)
                  IconButton(
                    onPressed: onViewVisit,
                    icon: const Icon(Icons.medical_services_outlined),
                    tooltip: l10n.appointmentViewVisitButton,
                  ),
                if (onViewPatientFile != null)
                  IconButton(
                    onPressed: onViewPatientFile,
                    icon: const Icon(Icons.folder_open_outlined),
                    tooltip: l10n.appointmentViewPatientFileButton,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
