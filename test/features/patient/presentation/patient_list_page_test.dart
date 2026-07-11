import 'package:docentral/features/patient/domain/patient_record.dart';
import 'package:docentral/features/patient/domain/patient_repository.dart';
import 'package:docentral/features/patient/presentation/patient_list_page.dart';
import 'package:docentral/features/patient/presentation/providers/patient_repository_provider.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePatientRepository implements PatientRepository {
  _FakePatientRepository(this._patients);

  final List<PatientRecord> _patients;
  final List<PatientRecord> created = <PatientRecord>[];

  @override
  Stream<List<PatientRecord>> watchAll({
    required Role role,
    String query = '',
  }) {
    if (query.trim().isEmpty) return Stream.value(_patients);
    final String needle = query.trim().toLowerCase();
    final List<PatientRecord> filtered = _patients
        .where(
          (PatientRecord p) =>
              p.firstName.toLowerCase().contains(needle) ||
              p.lastName.toLowerCase().contains(needle),
        )
        .toList();
    return Stream.value(filtered);
  }

  @override
  Future<void> create({
    required Role role,
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    required String phone,
    String? email,
    String? historyNotes,
  }) async {
    created.add(
      PatientRecord(
        id: 'new-${created.length}',
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        phone: phone,
        email: email,
        historyNotes: historyNotes,
      ),
    );
  }
}

Future<ProviderContainer> _pumpPage(
  WidgetTester tester,
  _FakePatientRepository fakeRepository,
) async {
  final ProviderContainer container = ProviderContainer(
    overrides: [patientRepositoryProvider.overrideWithValue(fakeRepository)],
  );
  addTearDown(container.dispose);
  container.read(currentRoleProvider.notifier).setRole(Role.assistant);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PatientListPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  final List<PatientRecord> seedPatients = <PatientRecord>[
    PatientRecord(
      id: '1',
      firstName: 'Amine',
      lastName: 'Trabelsi',
      dateOfBirth: DateTime(1990, 5, 12),
      phone: '20123456',
    ),
    PatientRecord(
      id: '2',
      firstName: 'Sarra',
      lastName: 'Ben Youssef',
      dateOfBirth: DateTime(1985, 2, 3),
      phone: '99887766',
    ),
  ];

  testWidgets('renders patients from the repository', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, _FakePatientRepository(seedPatients));

    expect(find.text('Amine Trabelsi'), findsOneWidget);
    expect(find.text('Sarra Ben Youssef'), findsOneWidget);
  });

  testWidgets('typing in search narrows the list', (WidgetTester tester) async {
    await _pumpPage(tester, _FakePatientRepository(seedPatients));

    await tester.enterText(find.byType(TextField).first, 'tra');
    await tester.pumpAndSettle();

    expect(find.text('Amine Trabelsi'), findsOneWidget);
    expect(find.text('Sarra Ben Youssef'), findsNothing);
  });

  testWidgets('selecting a row shows patient details', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, _FakePatientRepository(seedPatients));

    await tester.tap(find.text('Amine Trabelsi'));
    await tester.pumpAndSettle();

    expect(find.text('20123456'), findsWidgets);
  });

  testWidgets('Add patient dialog validates required fields', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, _FakePatientRepository(seedPatients));

    await tester.tap(find.text('Add patient'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required'), findsWidgets);
  });
}
