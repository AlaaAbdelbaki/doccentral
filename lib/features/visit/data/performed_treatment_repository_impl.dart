import 'package:docentral/features/visit/domain/performed_treatment.dart';
import 'package:docentral/features/visit/domain/performed_treatment_repository.dart';
import 'package:docentral/features/visit/domain/visit_exceptions.dart';
import 'package:docentral/features/visit/domain/visit_status.dart';
import 'package:docentral/shared/data/database/app_database.dart';
import 'package:docentral/shared/data/database/tables/performed_treatments_table.dart';
import 'package:docentral/shared/data/database/tables/visits_table.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/permission_guard.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class PerformedTreatmentRepositoryImpl implements PerformedTreatmentRepository {
  PerformedTreatmentRepositoryImpl(this._db, {Uuid uuid = const Uuid()})
    : _uuid = uuid;

  final AppDatabase _db;
  final Uuid _uuid;

  Future<Visit> _requireInProgressVisit(String visitId) async {
    final Visit visit = await (_db.select(
      _db.visits,
    )..where((Visits t) => t.id.equals(visitId))).getSingle();
    if (visit.status != VisitStatus.inProgress.name) {
      throw const VisitNotEditableException();
    }
    return visit;
  }

  @override
  Stream<List<PerformedTreatment>> watchForVisit({
    required Role role,
    required String visitId,
  }) {
    requirePermission(role, Permission.canViewVisits);

    final SimpleSelectStatement<
      $PerformedTreatmentsTable,
      PerformedTreatmentRow
    >
    select = _db.select(_db.performedTreatments)
      ..where(
        (PerformedTreatments t) =>
            t.visitId.equals(visitId) & t.deletedAt.isNull(),
      )
      ..orderBy([(PerformedTreatments t) => OrderingTerm.asc(t.createdAt)]);

    return select.watch().map(
      (List<PerformedTreatmentRow> rows) =>
          rows.map(_toRecord).toList(growable: false),
    );
  }

  PerformedTreatment _toRecord(PerformedTreatmentRow row) {
    return PerformedTreatment(
      id: row.id,
      visitId: row.visitId,
      toothNumber: row.toothNumber,
      procedureName: row.procedureName,
      unitPrice: row.unitPrice,
      quantity: row.quantity,
      recordedByUserId: row.recordedByUserId,
      recordedAt: row.createdAt,
    );
  }

  @override
  Future<String> addTreatment({
    required Role role,
    required String actorUserId,
    required String visitId,
    required String toothNumber,
    required String procedureName,
    required double unitPrice,
    required int quantity,
  }) async {
    requirePermission(role, Permission.canEditVisit);
    await _requireInProgressVisit(visitId);

    final String id = _uuid.v4();
    final DateTime now = DateTime.now().toUtc();
    await _db
        .into(_db.performedTreatments)
        .insert(
          PerformedTreatmentsCompanion.insert(
            id: id,
            visitId: visitId,
            toothNumber: toothNumber.trim(),
            procedureName: procedureName.trim(),
            unitPrice: unitPrice,
            quantity: quantity,
            recordedByUserId: actorUserId,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  @override
  Future<void> updateTreatment({
    required Role role,
    required String treatmentId,
    required String toothNumber,
    required String procedureName,
    required double unitPrice,
    required int quantity,
  }) async {
    requirePermission(role, Permission.canEditVisit);

    final PerformedTreatmentRow treatment = await (_db.select(
      _db.performedTreatments,
    )..where((PerformedTreatments t) => t.id.equals(treatmentId))).getSingle();
    await _requireInProgressVisit(treatment.visitId);

    await (_db.update(
      _db.performedTreatments,
    )..where((PerformedTreatments t) => t.id.equals(treatmentId))).write(
      PerformedTreatmentsCompanion(
        toothNumber: Value(toothNumber.trim()),
        procedureName: Value(procedureName.trim()),
        unitPrice: Value(unitPrice),
        quantity: Value(quantity),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<void> removeTreatment({
    required Role role,
    required String treatmentId,
  }) async {
    requirePermission(role, Permission.canEditVisit);

    final PerformedTreatmentRow treatment = await (_db.select(
      _db.performedTreatments,
    )..where((PerformedTreatments t) => t.id.equals(treatmentId))).getSingle();
    await _requireInProgressVisit(treatment.visitId);

    final DateTime now = DateTime.now().toUtc();
    await (_db.update(
      _db.performedTreatments,
    )..where((PerformedTreatments t) => t.id.equals(treatmentId))).write(
      PerformedTreatmentsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }
}
