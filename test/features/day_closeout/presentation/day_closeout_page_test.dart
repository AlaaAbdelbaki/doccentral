import 'package:docentral/features/day_closeout/domain/day_closeout_repository.dart';
import 'package:docentral/features/day_closeout/domain/day_closeout_summary.dart';
import 'package:docentral/features/day_closeout/presentation/day_closeout_page.dart';
import 'package:docentral/features/day_closeout/presentation/providers/day_closeout_repository_provider.dart';
import 'package:docentral/features/invoice/domain/payment_method.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDayCloseoutRepository implements DayCloseoutRepository {
  _FakeDayCloseoutRepository(this._summary);

  final DayCloseoutSummary _summary;

  @override
  Stream<DayCloseoutSummary> watchSummary({
    required Role role,
    required DateTime day,
  }) => Stream.value(_summary);
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required DayCloseoutSummary summary,
  Role role = Role.assistant,
}) async {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      dayCloseoutRepositoryProvider.overrideWithValue(
        _FakeDayCloseoutRepository(summary),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.read(currentRoleProvider.notifier).setRole(role);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DayCloseoutPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'shows the completed visits, invoice totals, and outstanding count',
    (WidgetTester tester) async {
      await _pumpPage(
        tester,
        summary: const DayCloseoutSummary(
          completedVisitsCount: 3,
          paymentTotalsByMethod: <PaymentMethod, double>{
            PaymentMethod.cash: 150,
            PaymentMethod.card: 50,
          },
          newInvoicesTotal: 400,
          outstandingInvoicesCount: 2,
        ),
      );

      expect(find.text('Completed visits'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Outstanding invoices'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('Card'), findsOneWidget);
    },
  );

  testWidgets('shows the no-payments empty state when nothing was recorded', (
    WidgetTester tester,
  ) async {
    await _pumpPage(
      tester,
      summary: const DayCloseoutSummary(
        completedVisitsCount: 0,
        paymentTotalsByMethod: <PaymentMethod, double>{},
        newInvoicesTotal: 0,
        outstandingInvoicesCount: 0,
      ),
    );

    expect(find.text('No payments recorded today'), findsOneWidget);
  });

  testWidgets('shows a permission-denied message for a Nurse', (
    WidgetTester tester,
  ) async {
    await _pumpPage(
      tester,
      role: Role.nurse,
      summary: const DayCloseoutSummary(
        completedVisitsCount: 0,
        paymentTotalsByMethod: <PaymentMethod, double>{},
        newInvoicesTotal: 0,
        outstandingInvoicesCount: 0,
      ),
    );

    expect(
      find.text("You don't have permission to view the Day Closeout summary."),
      findsOneWidget,
    );
    expect(find.text('Completed visits'), findsNothing);
  });
}
