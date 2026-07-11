import 'package:docentral/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Center(child: Text(l10n.navCalendar));
  }
}
