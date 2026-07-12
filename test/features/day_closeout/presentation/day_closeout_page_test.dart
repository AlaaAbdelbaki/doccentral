import 'dart:async';

import 'package:docentral/features/day_closeout/domain/day_closeout_exceptions.dart';
import 'package:docentral/features/day_closeout/domain/day_closeout_record.dart';
import 'package:docentral/features/day_closeout/domain/day_closeout_repository.dart';
import 'package:docentral/features/day_closeout/domain/day_closeout_summary.dart';
import 'package:docentral/features/day_closeout/presentation/day_closeout_page.dart';
import 'package:docentral/features/day_closeout/presentation/providers/day_closeout_repository_provider.dart';
import 'package:docentral/features/invoice/domain/payment_method.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/data/providers/current_user_id_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDayCloseoutRepository implements DayCloseoutRepository {
  _FakeDayCloseoutRepository(this._summary, {DayCloseoutRecord? initial})
    : _closeout = initial;

  final DayCloseoutSummary _summary;
  DayCloseoutRecord? _closeout;
  Object? confirmErrorToThrow;
  final List<double> confirmedCountedCash = <double>[];
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<DayCloseoutSummary> watchSummary({
    required Role role,
    required DateTime day,
  }) => Stream.value(_summary);

  @override
  Future<String> confirmCloseout({
    required Role role,
    required String actorUserId,
    required DateTime day,
    required double countedCash,
  }) async {
    if (confirmErrorToThrow != null) {
      throw confirmErrorToThrow!;
    }
    confirmedCountedCash.add(countedCash);
    final double expectedCash =
        _summary.paymentTotalsByMethod[PaymentMethod.cash] ?? 0;
    _closeout = DayCloseoutRecord(
      id: 'closeout-1',
      closeoutDate: DateTime(day.year, day.month, day.day),
      expectedCash: expectedCash,
      countedCash: countedCash,
      delta: expectedCash - countedCash,
      actorUserId: actorUserId,
      recordedAt: DateTime.now(),
    );
    _changes.add(null);
    return 'closeout-1';
  }

  @override
  Stream<DayCloseoutRecord?> watchCloseoutForDay({
    required Role role,
    required DateTime day,
  }) async* {
    yield _closeout;
    await for (final _ in _changes.stream) {
      yield _closeout;
    }
  }
}

Future<_FakeDayCloseoutRepository> _pumpPage(
  WidgetTester tester, {
  required DayCloseoutSummary summary,
  DayCloseoutRecord? initialCloseout,
  Role role = Role.assistant,
}) async {
  final _FakeDayCloseoutRepository fakeRepository = _FakeDayCloseoutRepository(
    summary,
    initial: initialCloseout,
  );
  addTearDown(() => fakeRepository._changes.close());
  final ProviderContainer container = ProviderContainer(
    overrides: [
      dayCloseoutRepositoryProvider.overrideWithValue(fakeRepository),
    ],
  );
  addTearDown(container.dispose);
  container.read(currentRoleProvider.notifier).setRole(role);
  container.read(currentUserIdProvider.notifier).setUserId('actor-1');

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
  return fakeRepository;
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

  testWidgets('the Confirm closeout button is hidden for a Nurse', (
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

    expect(find.text('Confirm closeout'), findsNothing);
  });

  testWidgets(
    'confirming closeout computes delta and shows expected/counted/delta',
    (WidgetTester tester) async {
      final _FakeDayCloseoutRepository fakeRepository = await _pumpPage(
        tester,
        summary: const DayCloseoutSummary(
          completedVisitsCount: 1,
          paymentTotalsByMethod: <PaymentMethod, double>{
            PaymentMethod.cash: 100,
          },
          newInvoicesTotal: 100,
          outstandingInvoicesCount: 0,
        ),
      );

      await tester.tap(find.text('Confirm closeout'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Counted cash'),
        '95',
      );
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeRepository.confirmedCountedCash, <double>[95]);
      expect(find.text('Day closeout confirmed.'), findsOneWidget);
      expect(find.text('Expected cash'), findsOneWidget);
      expect(find.text('Counted cash'), findsOneWidget);
      expect(find.text('Delta'), findsOneWidget);
      // Confirm button disappears once today's closeout exists.
      expect(find.text('Confirm closeout'), findsNothing);
    },
  );

  testWidgets(
    'the Confirm closeout button is hidden once today already has a closeout',
    (WidgetTester tester) async {
      await _pumpPage(
        tester,
        summary: const DayCloseoutSummary(
          completedVisitsCount: 0,
          paymentTotalsByMethod: <PaymentMethod, double>{},
          newInvoicesTotal: 0,
          outstandingInvoicesCount: 0,
        ),
        initialCloseout: DayCloseoutRecord(
          id: 'closeout-1',
          closeoutDate: DateTime.now(),
          expectedCash: 100,
          countedCash: 100,
          delta: 0,
          actorUserId: 'actor-1',
          recordedAt: DateTime.now(),
        ),
      );

      expect(find.text('Confirm closeout'), findsNothing);
      expect(find.text('Expected cash'), findsOneWidget);
    },
  );

  testWidgets(
    'shows an error when confirming a day that already has a closeout',
    (WidgetTester tester) async {
      final _FakeDayCloseoutRepository fakeRepository = await _pumpPage(
        tester,
        summary: const DayCloseoutSummary(
          completedVisitsCount: 0,
          paymentTotalsByMethod: <PaymentMethod, double>{},
          newInvoicesTotal: 0,
          outstandingInvoicesCount: 0,
        ),
      );
      fakeRepository.confirmErrorToThrow =
          const DayCloseoutAlreadyExistsException();

      await tester.tap(find.text('Confirm closeout'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Counted cash'),
        '0',
      );
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('This day has already been closed out.'),
        findsOneWidget,
      );
    },
  );
}
