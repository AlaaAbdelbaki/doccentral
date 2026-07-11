import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/router/app_destination.dart';
import 'package:flutter/material.dart';

/// Responsive navigation shell wrapping the app's top-level branches
/// (Calendar, Patients, Inventory, Day Closeout, Settings).
///
/// Pure presentation — knows nothing about GoRouter. The caller supplies
/// [currentDestination], [onItemChanged], and the routed content as
/// [child]. Below [wideBreakpoint] a bottom [NavigationBar] is used; at or
/// above it, a side [NavigationRail] is used instead.
class AppShell extends StatelessWidget {
  const AppShell({
    required this.child,
    required this.currentDestination,
    required this.onItemChanged,
    super.key,
  });

  final Widget child;
  final AppDestination currentDestination;
  final ValueChanged<AppDestination> onItemChanged;

  static const double wideBreakpoint = 800;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final int selectedIndex = AppDestination.values.indexOf(currentDestination);

    void handleIndexChanged(int index) =>
        onItemChanged(AppDestination.values[index]);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isWide = constraints.maxWidth >= wideBreakpoint;
        if (isWide) {
          return Scaffold(
            body: Row(
              children: <Widget>[
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: handleIndexChanged,
                  labelType: NavigationRailLabelType.all,
                  destinations: <NavigationRailDestination>[
                    for (final AppDestination destination
                        in AppDestination.values)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        label: Text(destination.toLocalized(l10n)),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
          );
        }

        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: handleIndexChanged,
            destinations: <Widget>[
              for (final AppDestination destination in AppDestination.values)
                NavigationDestination(
                  icon: Icon(destination.icon),
                  label: destination.toLocalized(l10n),
                ),
            ],
          ),
        );
      },
    );
  }
}
