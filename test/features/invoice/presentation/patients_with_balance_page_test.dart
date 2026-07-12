import 'dart:async';

import 'package:docentral/features/invoice/domain/patient_balance.dart';
import 'package:docentral/features/invoice/presentation/patients_with_balance_page.dart';
import 'package:docentral/features/patient/domain/patient_record.dart';
import 'package:docentral/features/patient/presentation/providers/selected_patient_provider.dart';
import 'package:docentral/features/invoice/domain/invoice_adjustment_type.dart';
import 'package:docentral/features/invoice/domain/invoice_item.dart';
import 'package:docentral/features/invoice/domain/invoice_record.dart';
import 'package:docentral/features/invoice/domain/invoice_repository.dart';
import 'package:docentral/features/invoice/presentation/providers/invoice_repository_provider.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeInvoiceRepository implements InvoiceRepository {
  _FakeInvoiceRepository(List<PatientBalance> balances) : _balances = balances;

  final List<PatientBalance> _balances;

  @override
  Stream<InvoiceRecord?> watchInvoiceForVisit({
    required Role role,
    required String visitId,
  }) => Stream.value(null);

  @override
  Stream<List<InvoiceItem>> watchItemsForInvoice({
    required Role role,
    required String invoiceId,
  }) => Stream.value(const <InvoiceItem>[]);

  @override
  Future<String> addAdjustment({
    required Role role,
    required String invoiceId,
    required InvoiceAdjustmentType adjustmentType,
    required String description,
    required double amount,
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Future<void> finalizeInvoice({
    required Role role,
    required String actorUserId,
    required String invoiceId,
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Future<void> voidInvoice({
    required Role role,
    required String actorUserId,
    required String invoiceId,
    required String reason,
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Stream<double> watchOutstandingBalanceForPatient({
    required Role role,
    required String patientId,
  }) => Stream.value(0);

  @override
  Stream<List<PatientBalance>> watchPatientsWithBalance({required Role role}) =>
      Stream.value(_balances);
}

Future<ProviderContainer> _pumpPage(
  WidgetTester tester, {
  required List<PatientBalance> balances,
}) async {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      invoiceRepositoryProvider.overrideWithValue(
        _FakeInvoiceRepository(balances),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.read(currentRoleProvider.notifier).setRole(Role.doctor);

  final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            const PatientsWithBalancePage(),
      ),
      GoRoute(
        path: '/patients',
        name: 'patients',
        // Watches selectedPatientProvider, mirroring the real PatientListPage,
        // so the autoDispose provider stays alive across this navigation.
        builder: (BuildContext context, GoRouterState state) => Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) {
            ref.watch(selectedPatientProvider);
            return const Scaffold(body: Text('Patients page'));
          },
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  PatientRecord patient({required String id, required String firstName}) =>
      PatientRecord(
        id: id,
        firstName: firstName,
        lastName: 'Trabelsi',
        dateOfBirth: DateTime(1990),
        phone: '20123456',
      );

  testWidgets('shows the empty state when no patients have a balance', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, balances: const <PatientBalance>[]);

    expect(
      find.text('No patients currently have an outstanding balance'),
      findsOneWidget,
    );
  });

  testWidgets('lists patients with their balance', (WidgetTester tester) async {
    await _pumpPage(
      tester,
      balances: <PatientBalance>[
        PatientBalance(
          patient: patient(id: 'p1', firstName: 'Amine'),
          balance: 70,
          lastPaymentDate: DateTime(2026, 1, 20),
        ),
      ],
    );

    expect(find.text('Amine Trabelsi'), findsOneWidget);
    expect(find.textContaining('70'), findsWidgets);
  });

  testWidgets('shows "no payment yet" for a patient who never paid', (
    WidgetTester tester,
  ) async {
    await _pumpPage(
      tester,
      balances: <PatientBalance>[
        PatientBalance(
          patient: patient(id: 'p1', firstName: 'Amine'),
          balance: 70,
        ),
      ],
    );

    expect(find.text('No payment made yet'), findsOneWidget);
  });

  testWidgets('sorts by balance descending by default', (
    WidgetTester tester,
  ) async {
    await _pumpPage(
      tester,
      balances: <PatientBalance>[
        PatientBalance(
          patient: patient(id: 'p1', firstName: 'Amine'),
          balance: 30,
        ),
        PatientBalance(
          patient: patient(id: 'p2', firstName: 'Sarra'),
          balance: 90,
        ),
      ],
    );

    final Finder titles = find.byType(ListTile);
    final ListTile first = tester.widget(titles.first);
    expect((first.title! as Text).data, 'Sarra Trabelsi');
  });

  testWidgets(
    'tapping a row selects the patient and navigates to the Patient File',
    (WidgetTester tester) async {
      final ProviderContainer container = await _pumpPage(
        tester,
        balances: <PatientBalance>[
          PatientBalance(
            patient: patient(id: 'p1', firstName: 'Amine'),
            balance: 70,
          ),
        ],
      );

      await tester.tap(find.text('Amine Trabelsi'));
      await tester.pumpAndSettle();

      expect(container.read(selectedPatientProvider)?.id, 'p1');
      expect(find.text('Patients page'), findsOneWidget);
    },
  );
}
