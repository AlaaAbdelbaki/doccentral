import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/router/app_routes.dart';
import 'package:flutter/material.dart';

/// Top-level navigation destinations shown in the app shell, each bound to
/// its [AppRoutes] entry so the nav UI and routing stay in sync.
enum AppDestination {
  calendar(icon: Icons.calendar_today_outlined, route: AppRoutes.calendar),
  patients(icon: Icons.people_outline, route: AppRoutes.patients),
  inventory(icon: Icons.inventory_2_outlined, route: AppRoutes.inventory),
  dayCloseout(icon: Icons.fact_check_outlined, route: AppRoutes.dayCloseout),
  settings(icon: Icons.settings_outlined, route: AppRoutes.settings);

  const AppDestination({required this.icon, required this.route});

  final IconData icon;
  final AppRoutes route;

  String toLocalized(AppLocalizations l10n) {
    switch (this) {
      case AppDestination.calendar:
        return l10n.navCalendar;
      case AppDestination.patients:
        return l10n.navPatients;
      case AppDestination.inventory:
        return l10n.navInventory;
      case AppDestination.dayCloseout:
        return l10n.navDayCloseout;
      case AppDestination.settings:
        return l10n.navSettings;
    }
  }
}
