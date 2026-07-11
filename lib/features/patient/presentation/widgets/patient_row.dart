part of '../patient_list_page.dart';

class _PatientRow extends StatelessWidget {
  const _PatientRow({
    required this.patient,
    required this.selected,
    required this.onTap,
  });

  final PatientRecord patient;
  final bool selected;
  final VoidCallback onTap;

  static const List<Color> _avatarPalette = <Color>[
    Color(0xFF1E88E5),
    Color(0xFF00897B),
    Color(0xFF8E24AA),
    Color(0xFFF9A825),
    Color(0xFFE53935),
  ];

  static String initials(String firstName, String lastName) {
    final String f = firstName.isNotEmpty ? firstName[0] : '';
    final String l = lastName.isNotEmpty ? lastName[0] : '';
    return (f + l).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final Color color =
        _avatarPalette[patient.id.hashCode.abs() % _avatarPalette.length];

    return ListTile(
      selected: selected,
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        child: Text(initials(patient.firstName, patient.lastName)),
      ),
      title: Text('${patient.firstName} ${patient.lastName}'),
      subtitle: Text(patient.phone),
    );
  }
}
