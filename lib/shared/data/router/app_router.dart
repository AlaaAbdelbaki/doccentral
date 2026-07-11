import 'package:docentral/features/appointment/presentation/calendar_page.dart';
import 'package:docentral/features/day_closeout/presentation/day_closeout_page.dart';
import 'package:docentral/features/inventory/presentation/inventory_list_page.dart';
import 'package:docentral/features/patient/presentation/patient_list_page.dart';
import 'package:docentral/features/settings/presentation/settings_page.dart';
import 'package:docentral/shared/data/router/app_destination.dart';
import 'package:docentral/shared/data/router/app_routes.dart';
import 'package:docentral/shared/design_system/widgets/app_shell.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.calendar.path,
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) {
              return AppShell(
                currentDestination:
                    AppDestination.values[navigationShell.currentIndex],
                onItemChanged: (AppDestination destination) {
                  final int index = AppDestination.values.indexOf(destination);
                  navigationShell.goBranch(
                    index,
                    initialLocation: index == navigationShell.currentIndex,
                  );
                },
                child: navigationShell,
              );
            },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.calendar.path,
                name: AppRoutes.calendar.name,
                builder: (BuildContext context, GoRouterState state) =>
                    const CalendarPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.patients.path,
                name: AppRoutes.patients.name,
                builder: (BuildContext context, GoRouterState state) =>
                    const PatientListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.inventory.path,
                name: AppRoutes.inventory.name,
                builder: (BuildContext context, GoRouterState state) =>
                    const InventoryListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.dayCloseout.path,
                name: AppRoutes.dayCloseout.name,
                builder: (BuildContext context, GoRouterState state) =>
                    const DayCloseoutPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.settings.path,
                name: AppRoutes.settings.name,
                builder: (BuildContext context, GoRouterState state) =>
                    const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
