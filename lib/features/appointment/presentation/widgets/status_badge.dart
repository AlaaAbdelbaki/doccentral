part of '../calendar_page.dart';

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final AppointmentStatus status;

  Color _color(BuildContext context) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Colors.blueGrey;
      case AppointmentStatus.checkedIn:
        return Colors.amber.shade800;
      case AppointmentStatus.completed:
        return Colors.green.shade700;
      case AppointmentStatus.cancelled:
        return Colors.red.shade700;
    }
  }

  String _label(AppLocalizations l10n) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return l10n.appointmentStatusScheduled;
      case AppointmentStatus.checkedIn:
        return l10n.appointmentStatusCheckedIn;
      case AppointmentStatus.completed:
        return l10n.appointmentStatusCompleted;
      case AppointmentStatus.cancelled:
        return l10n.appointmentStatusCancelled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final Color color = _color(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Text(
        _label(l10n),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
