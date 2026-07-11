part of '../patient_list_page.dart';

class _PatientSearchBar extends StatefulWidget {
  const _PatientSearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<_PatientSearchBar> createState() => _PatientSearchBarState();
}

class _PatientSearchBarState extends State<_PatientSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: l10n.patientSearchHint,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
