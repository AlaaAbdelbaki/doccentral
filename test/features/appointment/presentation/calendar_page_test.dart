import 'package:docentral/features/appointment/domain/appointment_record.dart';
import 'package:docentral/features/appointment/domain/appointment_repository.dart';
import 'package:docentral/features/appointment/domain/appointment_status.dart';
import 'package:docentral/features/appointment/presentation/calendar_page.dart';
import 'package:docentral/features/appointment/presentation/providers/appointment_repository_provider.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAppointmentRepository implements AppointmentRepository {
  _FakeAppointmentRepository(this._appointments);

  final List<AppointmentRecord> _appointments;

  @override
  Stream<List<AppointmentRecord>> watchToday({required Role role}) =>
      Stream.value(_appointments);

  @override
  Stream<List<AppointmentRecord>> watchRange({
    required Role role,
    required DateTime start,
    required DateTime end,
  }) => Stream.value(
    _appointments
        .where(
          (AppointmentRecord a) =>
              !a.startTime.isBefore(start) && a.startTime.isBefore(end),
        )
        .toList(),
  );
}

Future<void> _pumpPage(
  WidgetTester tester,
  List<AppointmentRecord> appointments,
) async {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      appointmentRepositoryProvider.overrideWithValue(
        _FakeAppointmentRepository(appointments),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.read(currentRoleProvider.notifier).setRole(Role.assistant);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CalendarPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows an empty state when there are no appointments today', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, const <AppointmentRecord>[]);

    expect(find.text('No appointments today'), findsOneWidget);
  });

  testWidgets('renders appointment rows with patient name and status badge', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime.now();
    await _pumpPage(tester, <AppointmentRecord>[
      AppointmentRecord(
        id: '1',
        patientId: 'p1',
        patientName: 'Amine Trabelsi',
        assignedUserId: 'dentist-1',
        startTime: DateTime(now.year, now.month, now.day, 9),
        endTime: DateTime(now.year, now.month, now.day, 9, 30),
        status: AppointmentStatus.scheduled,
        reason: 'Cleaning',
      ),
      AppointmentRecord(
        id: '2',
        patientId: 'p2',
        patientName: 'Sarra Ben Youssef',
        assignedUserId: 'dentist-1',
        startTime: DateTime(now.year, now.month, now.day, 10),
        endTime: DateTime(now.year, now.month, now.day, 10, 30),
        status: AppointmentStatus.checkedIn,
      ),
    ]);

    expect(find.text('Amine Trabelsi'), findsOneWidget);
    expect(find.text('Cleaning'), findsOneWidget);
    expect(find.text('Scheduled'), findsOneWidget);
    expect(find.text('Sarra Ben Youssef'), findsOneWidget);
    expect(find.text('No reason noted'), findsOneWidget);
    expect(find.text('Checked in'), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);
  });

  testWidgets('shows the low-stock side panel', (WidgetTester tester) async {
    await _pumpPage(tester, const <AppointmentRecord>[]);

    expect(find.text("Today's alerts"), findsOneWidget);
    expect(find.text('Low-stock items'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets(
    'switching to Week view shows today\'s appointment in its day column',
    (WidgetTester tester) async {
      final DateTime now = DateTime.now();
      await _pumpPage(tester, <AppointmentRecord>[
        AppointmentRecord(
          id: '1',
          patientId: 'p1',
          patientName: 'Amine Trabelsi',
          assignedUserId: 'dentist-1',
          startTime: DateTime(now.year, now.month, now.day, 9),
          endTime: DateTime(now.year, now.month, now.day, 9, 30),
          status: AppointmentStatus.scheduled,
        ),
      ]);

      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();

      expect(find.text('Amine Trabelsi'), findsOneWidget);
    },
  );

  testWidgets(
    'week navigation shifts the range and drops out-of-range appointments',
    (WidgetTester tester) async {
      final DateTime now = DateTime.now();
      await _pumpPage(tester, <AppointmentRecord>[
        AppointmentRecord(
          id: '1',
          patientId: 'p1',
          patientName: 'Amine Trabelsi',
          assignedUserId: 'dentist-1',
          startTime: DateTime(now.year, now.month, now.day, 9),
          endTime: DateTime(now.year, now.month, now.day, 9, 30),
          status: AppointmentStatus.scheduled,
        ),
      ]);

      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      expect(find.text('Amine Trabelsi'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(find.text('Amine Trabelsi'), findsNothing);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(find.text('Amine Trabelsi'), findsOneWidget);
    },
  );
}
