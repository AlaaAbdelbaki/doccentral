import 'package:docentral/features/patient/data/patient_repository_impl.dart';
import 'package:docentral/features/patient/domain/patient_exceptions.dart';
import 'package:docentral/features/patient/domain/patient_record.dart';
import 'package:docentral/shared/data/database/app_database.dart';
import 'package:docentral/shared/domain/exceptions/permission_denied_exception.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _createInMemoryDatabase() {
  return AppDatabase(NativeDatabase.memory());
}

void main() {
  late AppDatabase db;
  late PatientRepositoryImpl repository;

  setUp(() {
    db = _createInMemoryDatabase();
    repository = PatientRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seed() async {
    await repository.create(
      role: Role.assistant,
      firstName: 'Amine',
      lastName: 'Trabelsi',
      dateOfBirth: DateTime(1990, 5, 12),
      phone: '20123456',
    );
    await repository.create(
      role: Role.assistant,
      firstName: 'Sarra',
      lastName: 'Ben Youssef',
      dateOfBirth: DateTime(1985, 2, 3),
      phone: '99887766',
    );
  }

  group('PatientRepositoryImpl.create', () {
    test('creates a patient with all required fields', () async {
      await repository.create(
        role: Role.assistant,
        firstName: 'Amine',
        lastName: 'Trabelsi',
        dateOfBirth: DateTime(1990, 5, 12),
        phone: '20123456',
      );

      final List<PatientRecord> patients = await repository
          .watchAll(role: Role.assistant)
          .first;
      expect(patients.length, 1);
      expect(patients.first.firstName, 'Amine');
      expect(patients.first.lastName, 'Trabelsi');
    });

    test('throws PatientValidationException when firstName is blank', () {
      expect(
        () => repository.create(
          role: Role.assistant,
          firstName: '',
          lastName: 'Trabelsi',
          dateOfBirth: DateTime(1990, 5, 12),
          phone: '20123456',
        ),
        throwsA(isA<PatientValidationException>()),
      );
    });

    test('throws PatientValidationException when phone is blank', () {
      expect(
        () => repository.create(
          role: Role.assistant,
          firstName: 'Amine',
          lastName: 'Trabelsi',
          dateOfBirth: DateTime(1990, 5, 12),
          phone: '   ',
        ),
        throwsA(isA<PatientValidationException>()),
      );
    });

    test(
      'throws PermissionDeniedException when role lacks canCreatePatient',
      () {
        expect(
          () => repository.create(
            role: Role.nurse,
            firstName: 'Amine',
            lastName: 'Trabelsi',
            dateOfBirth: DateTime(1990, 5, 12),
            phone: '20123456',
          ),
          throwsA(isA<PermissionDeniedException>()),
        );
      },
    );
  });

  group('PatientRepositoryImpl.watchAll', () {
    test('returns all active patients when query is empty', () async {
      await seed();
      final List<PatientRecord> patients = await repository
          .watchAll(role: Role.doctor)
          .first;
      expect(patients.length, 2);
    });

    test('matches a partial, case-insensitive last name', () async {
      await seed();
      final List<PatientRecord> patients = await repository
          .watchAll(role: Role.doctor, query: 'tra')
          .first;
      expect(patients.length, 1);
      expect(patients.first.lastName, 'Trabelsi');
    });

    test('excludes soft-deleted patients', () async {
      await seed();
      final PatientRecord toDelete =
          (await repository.watchAll(role: Role.doctor).first).firstWhere(
            (PatientRecord p) => p.lastName == 'Trabelsi',
          );

      await (db.update(db.patients)..where((t) => t.id.equals(toDelete.id)))
          .write(PatientsCompanion(deletedAt: Value(DateTime.now())));

      final List<PatientRecord> patients = await repository
          .watchAll(role: Role.doctor)
          .first;
      expect(patients.length, 1);
      expect(patients.first.lastName, 'Ben Youssef');
    });
  });
}
