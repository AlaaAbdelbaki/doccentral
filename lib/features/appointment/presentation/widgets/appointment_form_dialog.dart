part of '../calendar_page.dart';

class AppointmentFormResult {
  const AppointmentFormResult({
    required this.patientId,
    required this.assignedUserId,
    required this.startTime,
    required this.endTime,
    this.reason,
    this.notes,
  });

  final String patientId;
  final String assignedUserId;
  final DateTime startTime;
  final DateTime endTime;
  final String? reason;
  final String? notes;
}

class _AppointmentFormDialog extends ConsumerStatefulWidget {
  const _AppointmentFormDialog({
    required this.onSubmit,
    required this.patients,
    required this.assignableUsers,
    this.initial,
    this.title,
    this.prefillPatientId,
    this.prefillAssignedUserId,
  });

  final void Function(AppointmentFormResult result) onSubmit;
  final List<PatientRecord> patients;
  final List<AssignableUser> assignableUsers;

  /// Non-null means "editing this exact appointment" — its id is used by
  /// the caller's onSubmit handler. For a fresh appointment prefilled from
  /// another one (the reschedule flow), use [prefillPatientId] /
  /// [prefillAssignedUserId] instead and leave this null.
  final AppointmentRecord? initial;
  final String? title;
  final String? prefillPatientId;
  final String? prefillAssignedUserId;

  @override
  ConsumerState<_AppointmentFormDialog> createState() =>
      _AppointmentFormDialogState();
}

class _AppointmentFormDialogState
    extends ConsumerState<_AppointmentFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  PatientRecord? _selectedPatient;
  String? _selectedAssignedUserId;
  DateTime? _startTime;
  DateTime? _endTime;
  String? _patientError;

  @override
  void initState() {
    super.initState();
    final AppointmentRecord? initial = widget.initial;
    if (initial != null) {
      for (final PatientRecord patient in widget.patients) {
        if (patient.id == initial.patientId) {
          _selectedPatient = patient;
          break;
        }
      }
      _selectedAssignedUserId = initial.assignedUserId;
      _startTime = initial.startTime;
      _endTime = initial.endTime;
      _reasonController.text = initial.reason ?? '';
      _notesController.text = initial.notes ?? '';
    } else {
      final String? prefillPatientId = widget.prefillPatientId;
      if (prefillPatientId != null) {
        for (final PatientRecord patient in widget.patients) {
          if (patient.id == prefillPatientId) {
            _selectedPatient = patient;
            break;
          }
        }
      }
      final String? prefillAssignedUserId = widget.prefillAssignedUserId;
      if (prefillAssignedUserId != null) {
        _selectedAssignedUserId = prefillAssignedUserId;
      } else {
        for (final AssignableUser user in widget.assignableUsers) {
          if (user.role == Role.doctor) {
            _selectedAssignedUserId = user.id;
            break;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickStartTime() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = _startTime ?? now;
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null || !mounted) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null) return;

    final DateTime newStart = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      _startTime = newStart;
      _endTime = newStart.add(const Duration(minutes: 30));
    });
  }

  Future<void> _pickEndTime() async {
    final DateTime? start = _startTime;
    if (start == null) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endTime ?? start),
    );
    if (time == null) return;

    setState(() {
      _endTime = DateTime(
        start.year,
        start.month,
        start.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _submit(AppLocalizations l10n) {
    final bool formValid = _formKey.currentState?.validate() ?? false;
    final PatientRecord? patient = _selectedPatient;
    if (patient == null) {
      setState(() => _patientError = l10n.patientRequiredFieldError);
    }
    final String? assignedUserId = _selectedAssignedUserId;
    final DateTime? startTime = _startTime;
    final DateTime? endTime = _endTime;
    if (!formValid ||
        patient == null ||
        assignedUserId == null ||
        startTime == null ||
        endTime == null) {
      return;
    }

    widget.onSubmit(
      AppointmentFormResult(
        patientId: patient.id,
        assignedUserId: assignedUserId,
        startTime: startTime,
        endTime: endTime,
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final DateTime? startTime = _startTime;
    final DateTime? endTime = _endTime;

    return AlertDialog(
      title: Text(
        widget.title ??
            (widget.initial == null
                ? l10n.appointmentFormTitle
                : l10n.appointmentEditFormTitle),
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DropdownButtonFormField<PatientRecord>(
                  initialValue: _selectedPatient,
                  decoration: InputDecoration(
                    labelText: l10n.appointmentPatientField,
                    errorText: _patientError,
                  ),
                  items: <DropdownMenuItem<PatientRecord>>[
                    for (final PatientRecord patient in widget.patients)
                      DropdownMenuItem<PatientRecord>(
                        value: patient,
                        child: Text('${patient.firstName} ${patient.lastName}'),
                      ),
                  ],
                  onChanged: (PatientRecord? patient) {
                    setState(() {
                      _selectedPatient = patient;
                      _patientError = null;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _selectedAssignedUserId,
                  decoration: InputDecoration(
                    labelText: l10n.appointmentAssignedUserField,
                  ),
                  items: <DropdownMenuItem<String>>[
                    for (final AssignableUser user in widget.assignableUsers)
                      DropdownMenuItem<String>(
                        value: user.id,
                        child: Text(user.name),
                      ),
                  ],
                  onChanged: (String? userId) {
                    setState(() => _selectedAssignedUserId = userId);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                InkWell(
                  onTap: _pickStartTime,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.appointmentStartTimeField,
                    ),
                    child: Text(
                      startTime == null
                          ? ''
                          : DateFormat('dd/MM/yyyy HH:mm').format(startTime),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                InkWell(
                  onTap: startTime == null ? null : _pickEndTime,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.appointmentEndTimeField,
                    ),
                    child: Text(
                      endTime == null
                          ? ''
                          : DateFormat('dd/MM/yyyy HH:mm').format(endTime),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: l10n.appointmentReasonField,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: l10n.appointmentNotesField,
                  ),
                  maxLines: 3,
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
