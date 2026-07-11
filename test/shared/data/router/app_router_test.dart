import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/router/app_router.dart';
import 'package:docentral/shared/data/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<GoRouter> _pumpRouter(WidgetTester tester) async {
  final ProviderContainer container = ProviderContainer();
  addTearDown(container.dispose);
  final GoRouter router = container.read(appRouterProvider);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('starts on the calendar destination', (
    WidgetTester tester,
  ) async {
    await _pumpRouter(tester);

    expect(find.text("Today's Calendar"), findsWidgets);
  });

  testWidgets('going to each registered route shows its page', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pumpRouter(tester);

    router.go(AppRoutes.patients.path);
    await tester.pumpAndSettle();
    expect(find.text('Patients'), findsWidgets);

    router.go(AppRoutes.inventory.path);
    await tester.pumpAndSettle();
    expect(find.text('Inventory'), findsWidgets);

    router.go(AppRoutes.dayCloseout.path);
    await tester.pumpAndSettle();
    expect(find.text('Day Closeout'), findsWidgets);

    router.go(AppRoutes.settings.path);
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);
  });
}
