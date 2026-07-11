part of '../calendar_page.dart';

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.assignableUsers});

  final List<AssignableUser> assignableUsers;

  Future<void> _pickDateRange(BuildContext context, WidgetRef ref) async {
    final DateTime now = DateTime.now();
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (range == null) return;
    ref
        .read(appointmentFiltersControllerProvider.notifier)
        .setDateRange(range.start, range.end);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppointmentFilters filters = ref.watch(
      appointmentFiltersControllerProvider,
    );
    final AppointmentFiltersController controller = ref.read(
      appointmentFiltersControllerProvider.notifier,
    );

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          OutlinedButton.icon(
            onPressed: () => _pickDateRange(context, ref),
            icon: const Icon(Icons.date_range_outlined),
            label: Text(
              filters.startDate == null
                  ? l10n.appointmentFilterPickDateRange
                  : '${DateFormat('dd/MM/yyyy').format(filters.startDate!)} '
                        '- ${DateFormat('dd/MM/yyyy').format(filters.endDate ?? filters.startDate!)}',
            ),
          ),
          SizedBox(
            width: 200,
            child: TextField(
              decoration: InputDecoration(
                labelText: l10n.appointmentFilterPatientName,
                isDense: true,
              ),
              onChanged: controller.setPatientNameQuery,
            ),
          ),
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<AppointmentStatus?>(
              initialValue: filters.status,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.appointmentFilterStatus,
                isDense: true,
              ),
              items: <DropdownMenuItem<AppointmentStatus?>>[
                DropdownMenuItem<AppointmentStatus?>(
                  child: Text(l10n.appointmentFilterAllStatuses),
                ),
                for (final AppointmentStatus status in AppointmentStatus.values)
                  DropdownMenuItem<AppointmentStatus?>(
                    value: status,
                    child: Text(_StatusBadge.labelFor(l10n, status)),
                  ),
              ],
              onChanged: controller.setStatus,
            ),
          ),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String?>(
              initialValue: filters.assignedUserId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.appointmentAssignedUserField,
                isDense: true,
              ),
              items: <DropdownMenuItem<String?>>[
                DropdownMenuItem<String?>(
                  child: Text(l10n.appointmentFilterAllStaff),
                ),
                for (final AssignableUser user in assignableUsers)
                  DropdownMenuItem<String?>(
                    value: user.id,
                    child: Text(user.name),
                  ),
              ],
              onChanged: controller.setAssignedUserId,
            ),
          ),
          if (filters.isActive)
            TextButton.icon(
              onPressed: controller.clearAll,
              icon: const Icon(Icons.clear),
              label: Text(l10n.appointmentFilterClearAll),
            ),
        ],
      ),
    );
  }
}
