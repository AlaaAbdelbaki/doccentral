import 'dart:io';

import 'package:docentral/shared/data/database/database_key_service.dart';
import 'package:docentral/shared/data/database/tables/appointment_cancellations_table.dart';
import 'package:docentral/shared/data/database/tables/appointment_edit_logs_table.dart';
import 'package:docentral/shared/data/database/tables/appointment_planned_treatments_table.dart';
import 'package:docentral/shared/data/database/tables/appointments_table.dart';
import 'package:docentral/shared/data/database/tables/attachments_table.dart';
import 'package:docentral/shared/data/database/tables/clinics_table.dart';
import 'package:docentral/shared/data/database/tables/day_closeout_reopen_logs_table.dart';
import 'package:docentral/shared/data/database/tables/day_closeouts_table.dart';
import 'package:docentral/shared/data/database/tables/invoice_finalizations_table.dart';
import 'package:docentral/shared/data/database/tables/invoice_items_table.dart';
import 'package:docentral/shared/data/database/tables/invoice_voids_table.dart';
import 'package:docentral/shared/data/database/tables/inventory_items_table.dart';
import 'package:docentral/shared/data/database/tables/invoices_table.dart';
import 'package:docentral/shared/data/database/tables/patient_edit_logs_table.dart';
import 'package:docentral/shared/data/database/tables/patients_table.dart';
import 'package:docentral/shared/data/database/tables/payments_table.dart';
import 'package:docentral/shared/data/database/tables/performed_treatments_table.dart';
import 'package:docentral/shared/data/database/tables/planned_treatments_table.dart';
import 'package:docentral/shared/data/database/tables/restock_events_table.dart';
import 'package:docentral/shared/data/database/tables/roles_table.dart';
import 'package:docentral/shared/data/database/tables/stock_adjustments_table.dart';
import 'package:docentral/shared/data/database/tables/user_roles_table.dart';
import 'package:docentral/shared/data/database/tables/users_table.dart';
import 'package:docentral/shared/data/database/tables/visit_unlock_logs_table.dart';
import 'package:docentral/shared/data/database/tables/visits_table.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Clinics,
    Patients,
    Users,
    Roles,
    UserRoles,
    PatientEditLogs,
    Appointments,
    AppointmentEditLogs,
    AppointmentCancellations,
    Visits,
    PerformedTreatments,
    Invoices,
    InvoiceItems,
    VisitUnlockLogs,
    InvoiceFinalizations,
    Payments,
    InvoiceVoids,
    PlannedTreatments,
    AppointmentPlannedTreatments,
    InventoryItems,
    RestockEvents,
    StockAdjustments,
    DayCloseouts,
    DayCloseoutReopenLogs,
    Attachments,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? _openEncryptedConnection());

  @override
  int get schemaVersion => 24;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) await m.createTable(patients);
      if (from < 3) {
        await m.addColumn(clinics, clinics.locale);
        await m.addColumn(clinics, clinics.currency);
        await m.createTable(users);
        await m.createTable(roles);
        await m.createTable(userRoles);
      }
      if (from < 4) await m.createTable(patientEditLogs);
      if (from < 5) await m.createTable(appointments);
      if (from < 6) await m.createTable(appointmentEditLogs);
      if (from < 7) {
        await m.addColumn(
          appointments,
          appointments.rescheduledToAppointmentId,
        );
        await m.createTable(appointmentCancellations);
      }
      if (from < 8) await m.createTable(visits);
      if (from < 9) await m.addColumn(visits, visits.inProgressAt);
      if (from < 10) await m.createTable(performedTreatments);
      if (from < 11) {
        await m.addColumn(visits, visits.diagnosis);
        await m.addColumn(visits, visits.clinicalNotes);
      }
      if (from < 12) {
        await m.addColumn(visits, visits.endedAt);
        await m.createTable(invoices);
        await m.createTable(invoiceItems);
      }
      if (from < 13) await m.createTable(visitUnlockLogs);
      if (from < 14) await m.createTable(invoiceFinalizations);
      if (from < 15) await m.createTable(payments);
      if (from < 16) await m.createTable(invoiceVoids);
      if (from < 17) await m.createTable(plannedTreatments);
      if (from < 18) await m.createTable(appointmentPlannedTreatments);
      if (from < 19) await m.createTable(inventoryItems);
      if (from < 20) await m.createTable(restockEvents);
      if (from < 21) await m.createTable(stockAdjustments);
      if (from < 22) await m.createTable(dayCloseouts);
      if (from < 23) {
        await m.addColumn(dayCloseouts, dayCloseouts.reopenedAt);
        await m.createTable(dayCloseoutReopenLogs);
      }
      if (from < 24) await m.createTable(attachments);
    },
  );
}

QueryExecutor _openEncryptedConnection() {
  return LazyDatabase(() async {
    const keyService = DatabaseKeyService(FlutterSecureStorage());
    final encryptionKey = await keyService.getOrCreateKey();

    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'docentral.sqlite'));

    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        db.execute("PRAGMA key = '$encryptionKey'");
      },
    );
  });
}
