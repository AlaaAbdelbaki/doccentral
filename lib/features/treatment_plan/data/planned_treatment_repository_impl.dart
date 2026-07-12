import 'package:docentral/features/treatment_plan/domain/planned_treatment.dart';
import 'package:docentral/features/treatment_plan/domain/planned_treatment_repository.dart';
import 'package:docentral/features/treatment_plan/domain/planned_treatment_status.dart';
import 'package:docentral/shared/data/database/app_database.dart';
import 'package:docentral/shared/data/database/tables/planned_treatments_table.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/permission_guard.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class PlannedTreatmentRepositoryImpl implements PlannedTreatmentRepository {
  PlannedTreatmentRepositoryImpl(this._db, {Uuid uuid = const Uuid()})
    : _uuid = uuid;

  final AppDatabase _db;
  final Uuid _uuid;

  PlannedTreatment _toRecord(PlannedTreatmentRow row) {
    return PlannedTreatment(
      id: row.id,
      patientId: row.patientId,
      procedureName: row.procedureName,
      toothNumber: row.toothNumber,
      estimatedUnitPrice: row.estimatedUnitPrice,
      sequenceNumber: row.sequenceNumber,
      status: PlannedTreatmentStatus.values.byName(row.status),
      targetDate: row.targetDate,
    );
  }

  @override
  Stream<List<PlannedTreatment>> watchForPatient({
    required Role role,
    required String patientId,
  }) {
    requirePermission(role, Permission.canViewPatients);

    final SimpleSelectStatement<$PlannedTreatmentsTable, PlannedTreatmentRow>
    select = _db.select(_db.plannedTreatments)
      ..where(
        (PlannedTreatments t) =>
            t.patientId.equals(patientId) & t.deletedAt.isNull(),
      )
      ..orderBy([(PlannedTreatments t) => OrderingTerm.asc(t.sequenceNumber)]);

    return select.watch().map(
      (List<PlannedTreatmentRow> rows) =>
          rows.map(_toRecord).toList(growable: false),
    );
  }

  @override
  Future<String> addPlannedTreatment({
    required Role role,
    required String patientId,
    required String procedureName,
    required String toothNumber,
    required double estimatedUnitPrice,
    DateTime? targetDate,
  }) async {
    requirePermission(role, Permission.canManageTreatmentPlan);

    return _db.transaction(() async {
      final List<PlannedTreatmentRow> existing = await (_db.select(
        _db.plannedTreatments,
      )..where((PlannedTreatments t) => t.patientId.equals(patientId))).get();
      final int nextSequence =
          existing.fold(
            0,
            (int max, PlannedTreatmentRow row) =>
                row.sequenceNumber > max ? row.sequenceNumber : max,
          ) +
          1;

      final DateTime now = DateTime.now().toUtc();
      final String id = _uuid.v4();

      await _db
          .into(_db.plannedTreatments)
          .insert(
            PlannedTreatmentsCompanion.insert(
              id: id,
              patientId: patientId,
              procedureName: procedureName.trim(),
              toothNumber: toothNumber.trim(),
              estimatedUnitPrice: estimatedUnitPrice,
              sequenceNumber: nextSequence,
              targetDate: Value(targetDate?.toUtc()),
              status: const Value('planned'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      return id;
    });
  }
}
