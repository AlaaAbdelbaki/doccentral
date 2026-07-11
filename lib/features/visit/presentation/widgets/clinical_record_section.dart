part of '../visit_detail_page.dart';

class _ClinicalRecordSection extends ConsumerStatefulWidget {
  const _ClinicalRecordSection({
    super.key,
    required this.visitId,
    required this.diagnosis,
    required this.clinicalNotes,
    required this.editable,
  });

  final String visitId;
  final String? diagnosis;
  final String? clinicalNotes;
  final bool editable;

  @override
  ConsumerState<_ClinicalRecordSection> createState() =>
      _ClinicalRecordSectionState();
}

class _ClinicalRecordSectionState
    extends ConsumerState<_ClinicalRecordSection> {
  late final TextEditingController _diagnosisController = TextEditingController(
    text: widget.diagnosis,
  );
  late final TextEditingController _notesController = TextEditingController(
    text: widget.clinicalNotes,
  );
  late final FocusNode _diagnosisFocusNode = FocusNode()
    ..addListener(_onDiagnosisFocusChange);
  late final FocusNode _notesFocusNode = FocusNode()
    ..addListener(_onNotesFocusChange);

  void _onDiagnosisFocusChange() {
    if (!_diagnosisFocusNode.hasFocus) _save();
  }

  void _onNotesFocusChange() {
    if (!_notesFocusNode.hasFocus) _save();
  }

  void _save() {
    ref
        .read(visitControllerProvider.notifier)
        .updateClinicalRecord(
          visitId: widget.visitId,
          diagnosis: _diagnosisController.text,
          clinicalNotes: _notesController.text,
        );
  }

  @override
  void dispose() {
    _diagnosisFocusNode.dispose();
    _notesFocusNode.dispose();
    _diagnosisController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _diagnosisController,
            focusNode: _diagnosisFocusNode,
            readOnly: !widget.editable,
            maxLines: null,
            minLines: 2,
            decoration: InputDecoration(labelText: l10n.visitDiagnosisField),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _notesController,
            focusNode: _notesFocusNode,
            readOnly: !widget.editable,
            maxLines: null,
            minLines: 3,
            decoration: InputDecoration(
              labelText: l10n.visitClinicalNotesField,
            ),
          ),
        ],
      ),
    );
  }
}
