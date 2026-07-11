import 'package:docentral/features/appointment/presentation/calendar_page.dart';
import 'package:docentral/features/auth/presentation/sign_in_page.dart';
import 'package:docentral/features/clinic/presentation/providers/has_local_clinic_provider.dart';
import 'package:docentral/features/clinic/presentation/providers/resolved_role_provider.dart';
import 'package:docentral/features/clinic/presentation/sign_up_page.dart';
import 'package:docentral/features/day_closeout/presentation/day_closeout_page.dart';
import 'package:docentral/features/inventory/presentation/inventory_list_page.dart';
import 'package:docentral/features/patient/presentation/patient_list_page.dart';
import 'package:docentral/features/settings/presentation/settings_page.dart';
import 'package:docentral/shared/data/router/app_destination.dart';
import 'package:docentral/shared/data/router/app_routes.dart';
import 'package:docentral/shared/design_system/widgets/app_shell.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// Notifies GoRouter to re-run its redirect once [hasLocalClinicProvider] or
/// [resolvedRoleProvider] resolves/changes — a plain `ref.read` snapshot
/// inside `redirect:` would otherwise never be re-checked after the initial
/// (loading) evaluation, or after sign-in/sign-out.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(hasLocalClinicProvider, (
      AsyncValue<bool>? previous,
      AsyncValue<bool> next,
    ) {
      notifyListeners();
    });
    ref.listen(resolvedRoleProvider, (
      AsyncValue<Role?>? previous,
      AsyncValue<Role?> next,
    ) {
      notifyListeners();
    });
  }
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final _AuthRefreshNotifier refreshNotifier = _AuthRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.calendar.path,
    refreshListenable: refreshNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final AsyncValue<bool> hasClinicAsync = ref.read(hasLocalClinicProvider);
      final AsyncValue<Role?> roleAsync = ref.read(resolvedRoleProvider);
      if (hasClinicAsync.isLoading || roleAsync.isLoading) return null;

      final bool hasClinic = hasClinicAsync.value ?? false;
      final Role? role = roleAsync.value;
      final String location = state.matchedLocation;

      if (!hasClinic) {
        return location == AppRoutes.signUp.path ? null : AppRoutes.signUp.path;
      }
      if (location == AppRoutes.signUp.path) return AppRoutes.calendar.path;

      if (role == null) {
        return location == AppRoutes.signIn.path ? null : AppRoutes.signIn.path;
      }
      if (location == AppRoutes.signIn.path) return AppRoutes.calendar.path;

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.signUp.path,
        name: AppRoutes.signUp.name,
        builder: (BuildContext context, GoRouterState state) =>
            const SignUpPage(),
      ),
      GoRoute(
        path: AppRoutes.signIn.path,
        name: AppRoutes.signIn.name,
        builder: (BuildContext context, GoRouterState state) =>
            const SignInPage(),
      ),
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
