import 'package:docentral/features/appointment/domain/appointment_exceptions.dart';
import 'package:docentral/features/appointment/domain/appointment_status.dart';
import 'package:docentral/features/invoice/domain/invoice_status.dart';
import 'package:docentral/features/visit/domain/visit_exceptions.dart';
import 'package:docentral/features/visit/domain/visit_record.dart';
import 'package:docentral/features/visit/domain/visit_repository.dart';
import 'package:docentral/features/visit/domain/visit_status.dart';
import 'package:docentral/shared/data/database/app_database.dart';
import 'package:docentral/shared/data/database/tables/appointments_table.dart';
import 'package:docentral/shared/data/database/tables/performed_treatments_table.dart';
import 'package:docentral/shared/data/database/tables/visits_table.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/permission_guard.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class VisitRepositoryImpl implements VisitRepository {
  VisitRepositoryImpl(this._db, {Uuid uuid = const Uuid()}) : _uuid = uuid;

  final AppDatabase _db;
  final Uuid _uuid;

  @override
  Future<String> checkIn({
    required Role role,
    required String appointmentId,
  }) async {
    requirePermission(role, Permission.canCheckInPatient);

    return _db.transaction(() async {
      final Appointment appointment = await (_db.select(
        _db.appointments,
      )..where((Appointments t) => t.id.equals(appointmentId))).getSingle();

      if (appointment.status != AppointmentStatus.scheduled.name) {
        throw const AppointmentNotEditableException();
      }

      final DateTime now = DateTime.now().toUtc();

      await (_db.update(
        _db.appointments,
      )..where((Appointments t) => t.id.equals(appointmentId))).write(
        AppointmentsCompanion(
          status: Value(AppointmentStatus.checkedIn.name),
          updatedAt: Value(now),
        ),
      );

      final String visitId = _uuid.v4();
      await _db
          .into(_db.visits)
          .insert(
            VisitsCompanion.insert(
              id: visitId,
              appointmentId: appointmentId,
              patientId: appointment.patientId,
              dentistId: appointment.assignedUserId,
              status: Value(VisitStatus.checkedIn.name),
              startedAt: now,
              createdAt: now,
              updatedAt: now,
            ),
          );
      return visitId;
    });
  }

  @override
  Stream<List<VisitRecord>> watchRecentVisits({
    required Role role,
    required String patientId,
    int limit = 3,
  }) {
    requirePermission(role, Permission.canViewVisits);

    final SimpleSelectStatement<$VisitsTable, Visit> select =
        _db.select(_db.visits)
          ..where((Visits t) => t.patientId.equals(patientId))
          ..orderBy([(Visits t) => OrderingTerm.desc(t.startedAt)])
          ..limit(limit);

    return select.watch().map(
      (List<Visit> rows) => rows.map(_toRecord).toList(growable: false),
    );
  }

  VisitRecord _toRecord(Visit row) {
    return VisitRecord(
      id: row.id,
      appointmentId: row.appointmentId,
      patientId: row.patientId,
      dentistId: row.dentistId,
      status: VisitStatus.values.byName(row.status),
      startedAt: row.startedAt,
      inProgressAt: row.inProgressAt,
      diagnosis: row.diagnosis,
      clinicalNotes: row.clinicalNotes,
      endedAt: row.endedAt,
    );
  }

  Future<Visit> _findByAppointmentId(String appointmentId) {
    return (_db.select(
      _db.visits,
    )..where((Visits t) => t.appointmentId.equals(appointmentId))).getSingle();
  }

  @override
  Stream<VisitRecord?> watchVisitForAppointment({
    required Role role,
    required String appointmentId,
  }) {
    requirePermission(role, Permission.canViewVisits);

    final SimpleSelectStatement<$VisitsTable, Visit> select = _db.select(
      _db.visits,
    )..where((Visits t) => t.appointmentId.equals(appointmentId));

    return select.watchSingleOrNull().map(
      (Visit? row) => row == null ? null : _toRecord(row),
    );
  }

  @override
  Future<void> startProgress({
    required Role role,
    required String appointmentId,
  }) async {
    requirePermission(role, Permission.canEditVisit);

    await _db.transaction(() async {
      final Visit visit = await _findByAppointmentId(appointmentId);

      if (visit.status != VisitStatus.checkedIn.name) {
        throw const VisitNotEditableException();
      }

      final DateTime now = DateTime.now().toUtc();
      await (_db.update(
        _db.visits,
      )..where((Visits t) => t.id.equals(visit.id))).write(
        VisitsCompanion(
          status: Value(VisitStatus.inProgress.name),
          inProgressAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    });
  }

  @override
  Future<void> updateClinicalRecord({
    required Role role,
    required String visitId,
    String? diagnosis,
    String? clinicalNotes,
  }) async {
    requirePermission(role, Permission.canAddClinicalNotes);

    final Visit visit = await (_db.select(
      _db.visits,
    )..where((Visits t) => t.id.equals(visitId))).getSingle();

    if (visit.status != VisitStatus.inProgress.name) {
      throw const VisitNotEditableException();
    }

    await (_db.update(
      _db.visits,
    )..where((Visits t) => t.id.equals(visitId))).write(
      VisitsCompanion(
        diagnosis: Value(diagnosis?.trim()),
        clinicalNotes: Value(clinicalNotes?.trim()),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<String> completeVisit({
    required Role role,
    required String actorUserId,
    required String visitId,
  }) async {
    requirePermission(role, Permission.canCompleteVisit);

    return _db.transaction(() async {
      final Visit visit = await (_db.select(
        _db.visits,
      )..where((Visits t) => t.id.equals(visitId))).getSingle();

      if (visit.status != VisitStatus.inProgress.name) {
        throw const VisitNotEditableException();
      }

      final List<PerformedTreatmentRow> treatments =
          await (_db.select(_db.performedTreatments)..where(
                (PerformedTreatments t) =>
                    t.visitId.equals(visitId) & t.deletedAt.isNull(),
              ))
              .get();

      if (treatments.isEmpty) {
        throw const VisitRequiresTreatmentException();
      }

      final DateTime now = DateTime.now().toUtc();

      await (_db.update(
        _db.visits,
      )..where((Visits t) => t.id.equals(visitId))).write(
        VisitsCompanion(
          status: Value(VisitStatus.completed.name),
          endedAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      final double totalAmount = treatments.fold(
        0,
        (double sum, PerformedTreatmentRow t) => sum + t.unitPrice * t.quantity,
      );

      final String invoiceId = _uuid.v4();
      await _db
          .into(_db.invoices)
          .insert(
            InvoicesCompanion.insert(
              id: invoiceId,
              patientId: visit.patientId,
              visitId: visitId,
              totalAmount: totalAmount,
              status: Value(InvoiceStatus.draft.name),
              createdByUserId: actorUserId,
              createdAt: now,
              updatedAt: now,
            ),
          );

      for (final PerformedTreatmentRow treatment in treatments) {
        await _db
            .into(_db.invoiceItems)
            .insert(
              InvoiceItemsCompanion.insert(
                id: _uuid.v4(),
                invoiceId: invoiceId,
                description: treatment.procedureName,
                toothNumber: Value(treatment.toothNumber),
                quantity: treatment.quantity,
                unitPrice: treatment.unitPrice,
                totalPrice: treatment.unitPrice * treatment.quantity,
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      return invoiceId;
    });
  }
}
