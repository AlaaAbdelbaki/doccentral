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
}
