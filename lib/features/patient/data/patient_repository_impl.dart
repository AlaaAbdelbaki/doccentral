import 'package:docentral/features/patient/domain/patient_exceptions.dart';
import 'package:docentral/features/patient/domain/patient_record.dart';
import 'package:docentral/features/patient/domain/patient_repository.dart';
import 'package:docentral/shared/data/database/app_database.dart';
import 'package:docentral/shared/data/database/tables/patients_table.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/permission_guard.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class PatientRepositoryImpl implements PatientRepository {
  PatientRepositoryImpl(this._db, {Uuid uuid = const Uuid()}) : _uuid = uuid;

  final AppDatabase _db;
  final Uuid _uuid;

  @override
  Stream<List<PatientRecord>> watchAll({
    required Role role,
    String query = '',
  }) {
    requirePermission(role, Permission.canViewPatients);

    final SimpleSelectStatement<$PatientsTable, Patient> select =
        _db.select(_db.patients)
          ..where((Patients t) => t.deletedAt.isNull())
          ..orderBy([(Patients t) => OrderingTerm.asc(t.lastName)]);

    if (query.trim().isNotEmpty) {
      final String needle = '%${query.trim().toLowerCase()}%';
      select.where(
        (Patients t) =>
            t.firstName.lower().like(needle) |
            t.lastName.lower().like(needle) |
            t.phone.like(needle),
      );
    }

    return select.watch().map(
      (List<Patient> rows) => rows.map(_toRecord).toList(growable: false),
    );
  }

  PatientRecord _toRecord(Patient row) {
    return PatientRecord(
      id: row.id,
      firstName: row.firstName,
      lastName: row.lastName,
      dateOfBirth: row.dateOfBirth,
      phone: row.phone,
      email: row.email,
      historyNotes: row.historyNotes,
    );
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
    requirePermission(role, Permission.canCreatePatient);

    if (firstName.trim().isEmpty) {
      throw const PatientValidationException('firstName');
    }
    if (lastName.trim().isEmpty) {
      throw const PatientValidationException('lastName');
    }
    if (phone.trim().isEmpty) {
      throw const PatientValidationException('phone');
    }

    final DateTime now = DateTime.now();
    await _db
        .into(_db.patients)
        .insert(
          PatientsCompanion.insert(
            id: _uuid.v4(),
            firstName: firstName.trim(),
            lastName: lastName.trim(),
            dateOfBirth: dateOfBirth,
            phone: phone.trim(),
            email: Value(email?.trim()),
            historyNotes: Value(historyNotes?.trim()),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  @override
  Future<void> updatePatient({
    required Role role,
    required String actorUserId,
    required String patientId,
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    required String phone,
    String? email,
    String? historyNotes,
  }) async {
    requirePermission(role, Permission.canEditPatient);

    final String trimmedFirstName = firstName.trim();
    final String trimmedLastName = lastName.trim();
    final String trimmedPhone = phone.trim();
    final String? trimmedEmail = email?.trim();
    final String? trimmedHistoryNotes = historyNotes?.trim();

    if (trimmedFirstName.isEmpty) {
      throw const PatientValidationException('firstName');
    }
    if (trimmedLastName.isEmpty) {
      throw const PatientValidationException('lastName');
    }
    if (trimmedPhone.isEmpty) {
      throw const PatientValidationException('phone');
    }

    await _db.transaction(() async {
      final Patient existing = await (_db.select(
        _db.patients,
      )..where((Patients t) => t.id.equals(patientId))).getSingle();

      final List<String> changedFields = <String>[
        if (existing.firstName != trimmedFirstName) 'firstName',
        if (existing.lastName != trimmedLastName) 'lastName',
        if (existing.dateOfBirth != dateOfBirth) 'dateOfBirth',
        if (existing.phone != trimmedPhone) 'phone',
        if (existing.email != trimmedEmail) 'email',
        if (existing.historyNotes != trimmedHistoryNotes) 'historyNotes',
      ];

      final DateTime now = DateTime.now().toUtc();

      await (_db.update(
        _db.patients,
      )..where((Patients t) => t.id.equals(patientId))).write(
        PatientsCompanion(
          firstName: Value(trimmedFirstName),
          lastName: Value(trimmedLastName),
          dateOfBirth: Value(dateOfBirth),
          phone: Value(trimmedPhone),
          email: Value(trimmedEmail),
          historyNotes: Value(trimmedHistoryNotes),
          updatedAt: Value(now),
        ),
      );

      if (changedFields.isNotEmpty) {
        await _db
            .into(_db.patientEditLogs)
            .insert(
              PatientEditLogsCompanion.insert(
                id: _uuid.v4(),
                patientId: patientId,
                actorUserId: actorUserId,
                changedFields: changedFields.join(','),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
    });
  }

  @override
  Future<void> deletePatient({
    required Role role,
    required String patientId,
  }) async {
    requirePermission(role, Permission.canDeletePatient);

    final DateTime now = DateTime.now().toUtc();
    await (_db.update(_db.patients)
          ..where((Patients t) => t.id.equals(patientId)))
        .write(PatientsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
  }
}
