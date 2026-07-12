import 'package:docentral/features/day_closeout/domain/day_closeout_record.dart';
import 'package:docentral/features/day_closeout/domain/day_closeout_summary.dart';
import 'package:docentral/shared/domain/rbac/role.dart';

abstract class DayCloseoutRepository {
  /// Streams the real-time summary (completed Visits, Payments by method,
  /// new Invoices total, outstanding Invoices count) for the clinic day
  /// containing [day].
  Stream<DayCloseoutSummary> watchSummary({
    required Role role,
    required DateTime day,
  });

  /// Confirms the Day Closeout for the clinic day containing [day]:
  /// expected cash is independently recomputed (sum of today's cash
  /// Payments, never trusting a client-supplied value) and delta is always
  /// derived from expectedCash - [countedCash]. Returns the record's id.
  ///
  /// If a closeout already exists for that date and is currently reopened
  /// (see [reopenCloseout]), this updates that same record in place (new
  /// counted cash, new delta, new timestamp) and re-locks it. Otherwise,
  /// throws [DayCloseoutAlreadyExistsException] if a (locked) closeout
  /// already exists for that date.
  Future<String> confirmCloseout({
    required Role role,
    required String actorUserId,
    required DateTime day,
    required double countedCash,
  });

  /// Streams the Day Closeout record for the clinic day containing [day],
  /// or null if that day has not been closed out yet.
  Stream<DayCloseoutRecord?> watchCloseoutForDay({
    required Role role,
    required DateTime day,
  });

  /// Reopens a closed day, unlocking its counted cash for re-entry. Logs
  /// the actor, timestamp, and [reason]. Doctor-only.
  ///
  /// Throws [PermissionDeniedException] for any other role.
  Future<void> reopenCloseout({
    required Role role,
    required String actorUserId,
    required String dayCloseoutId,
    required String reason,
  });
}
