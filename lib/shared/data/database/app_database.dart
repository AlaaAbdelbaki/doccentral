import 'dart:io';

import 'package:docentral/shared/data/database/database_key_service.dart';
import 'package:docentral/shared/data/database/tables/appointment_cancellations_table.dart';
import 'package:docentral/shared/data/database/tables/appointment_edit_logs_table.dart';
import 'package:docentral/shared/data/database/tables/appointments_table.dart';
import 'package:docentral/shared/data/database/tables/clinics_table.dart';
import 'package:docentral/shared/data/database/tables/invoice_items_table.dart';
import 'package:docentral/shared/data/database/tables/invoices_table.dart';
import 'package:docentral/shared/data/database/tables/patient_edit_logs_table.dart';
import 'package:docentral/shared/data/database/tables/patients_table.dart';
import 'package:docentral/shared/data/database/tables/performed_treatments_table.dart';
import 'package:docentral/shared/data/database/tables/roles_table.dart';
import 'package:docentral/shared/data/database/tables/user_roles_table.dart';
import 'package:docentral/shared/data/database/tables/users_table.dart';
import 'package:docentral/shared/data/database/tables/visits_table.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
// sqlcipher_flutter_libs provides the SQLCipher native library; importing it
// replaces the default sqlite3 with an encryption-capable build on all platforms.
// ignore: unused_import
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? _openEncryptedConnection());

  @override
  int get schemaVersion => 12;

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
