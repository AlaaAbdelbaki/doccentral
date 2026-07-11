import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/router/app_destination.dart';
import 'package:docentral/shared/design_system/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpShell(
  WidgetTester tester, {
  required Size surfaceSize,
  required ValueChanged<AppDestination> onItemChanged,
  AppDestination currentDestination = AppDestination.calendar,
}) async {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppShell(
        currentDestination: currentDestination,
        onItemChanged: onItemChanged,
        child: const Center(child: Text('content')),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows a NavigationRail at or above the wide breakpoint', (
    WidgetTester tester,
  ) async {
    await _pumpShell(
      tester,
      surfaceSize: const Size(1024, 768),
      onItemChanged: (_) {},
    );

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('shows a NavigationBar below the wide breakpoint', (
    WidgetTester tester,
  ) async {
    await _pumpShell(
      tester,
      surfaceSize: const Size(500, 800),
      onItemChanged: (_) {},
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('does not require horizontal scrolling at 800px desktop width', (
    WidgetTester tester,
  ) async {
    await _pumpShell(
      tester,
      surfaceSize: const Size(800, 600),
      onItemChanged: (_) {},
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollable), findsNothing);
  });

  testWidgets('tapping a destination reports the selected AppDestination', (
    WidgetTester tester,
  ) async {
    AppDestination? selected;
    await _pumpShell(
      tester,
      surfaceSize: const Size(1024, 768),
      onItemChanged: (AppDestination destination) => selected = destination,
    );

    await tester.tap(find.text('Patients'));
    await tester.pumpAndSettle();

    expect(selected, AppDestination.patients);
  });
}
