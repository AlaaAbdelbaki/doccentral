import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/router/app_destination.dart';
import 'package:docentral/shared/data/router/app_routes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each destination binds to a distinct AppRoutes entry', () {
    final Set<AppRoutes> routes = AppDestination.values
        .map((AppDestination d) => d.route)
        .toSet();
    expect(routes.length, AppDestination.values.length);
  });

  test(
    'toLocalized resolves the matching English label per destination',
    () async {
      final AppLocalizations l10n = await AppLocalizations.delegate.load(
        const Locale('en'),
      );

      expect(AppDestination.calendar.toLocalized(l10n), l10n.navCalendar);
      expect(AppDestination.patients.toLocalized(l10n), l10n.navPatients);
      expect(AppDestination.inventory.toLocalized(l10n), l10n.navInventory);
      expect(AppDestination.dayCloseout.toLocalized(l10n), l10n.navDayCloseout);
      expect(AppDestination.settings.toLocalized(l10n), l10n.navSettings);
    },
  );
}
