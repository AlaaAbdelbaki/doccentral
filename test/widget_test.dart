import 'package:docentral/app.dart';
import 'package:docentral/features/appointment/domain/appointment_record.dart';
import 'package:docentral/features/appointment/domain/appointment_repository.dart';
import 'package:docentral/features/appointment/presentation/providers/appointment_repository_provider.dart';
import 'package:docentral/features/clinic/domain/clinic_repository.dart';
import 'package:docentral/features/clinic/presentation/providers/clinic_repository_provider.dart';
import 'package:docentral/features/clinic/presentation/providers/resolved_role_provider.dart';
import 'package:docentral/shared/data/providers/shared_preferences_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAppointmentRepository implements AppointmentRepository {
  @override
  Stream<List<AppointmentRecord>> watchToday({required Role role}) =>
      Stream.value(const <AppointmentRecord>[]);

  @override
  Stream<List<AppointmentRecord>> watchRange({
    required Role role,
    required DateTime start,
    required DateTime end,
  }) => Stream.value(const <AppointmentRecord>[]);
}

class _FakeClinicRepository implements ClinicRepository {
  @override
  Future<bool> hasLocalClinic() async => true;

  @override
  Future<String> provisionClinic({
    required String clinicName,
    required String dentistFirstName,
    required String dentistLastName,
    required String email,
    required String password,
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Future<Role?> resolveRole(String authUserId) =>
      throw UnimplementedError('not exercised by this test');

  @override
  Future<String?> resolveUserId(String authUserId) =>
      throw UnimplementedError('not exercised by this test');

  @override
  Future<void> addStaffUser({
    required Role actingRole,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required Role role,
  }) => throw UnimplementedError('not exercised by this test');
}

void main() {
  testWidgets('DocCentralApp boots to the calendar destination', (
    WidgetTester tester,
  ) async {
    // Seed an explicit locale so the assertion isn't coupled to the app's
    // default language (French) — see locale_provider.dart.
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_locale': 'en',
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          clinicRepositoryProvider.overrideWithValue(_FakeClinicRepository()),
          resolvedRoleProvider.overrideWith((ref) async => Role.doctor),
          appointmentRepositoryProvider.overrideWithValue(
            _FakeAppointmentRepository(),
          ),
        ],
        child: const DocCentralApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The label appears both as nav destination text and as the page body,
    // and which nav layout renders depends on the test surface width.
    expect(find.text("Today's Calendar"), findsWidgets);
  });
}
