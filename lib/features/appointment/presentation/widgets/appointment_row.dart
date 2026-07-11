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
  });

  final AppointmentRecord appointment;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final VoidCallback? onCheckIn;
  final VoidCallback? onViewPatientFile;
  final VisitStatus? visitStatus;
  final VoidCallback? onStartVisit;

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
        child: Row(
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
            if (_outstandingBalance > 0) ...<Widget>[
              Text(
                NumberFormat.currency(
                  symbol: 'TND',
                  decimalDigits: 3,
                ).format(_outstandingBalance),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            _StatusBadge(status: appointment.status),
            if (onEdit != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: l10n.appointmentEditButton,
              ),
            ],
            if (onCancel != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: onCancel,
                icon: const Icon(Icons.event_busy_outlined),
                tooltip: l10n.appointmentCancelButton,
              ),
            ],
            if (onCheckIn != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: onCheckIn,
                icon: const Icon(Icons.how_to_reg_outlined),
                tooltip: l10n.appointmentCheckInButton,
              ),
            ],
            if (onViewPatientFile != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: onViewPatientFile,
                icon: const Icon(Icons.folder_open_outlined),
                tooltip: l10n.appointmentViewPatientFileButton,
              ),
            ],
            if (visitStatus == VisitStatus.inProgress) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.visitStatusInProgress,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
            if (onStartVisit != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: onStartVisit,
                icon: const Icon(Icons.play_circle_outline),
                tooltip: l10n.appointmentStartVisitButton,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
