import 'package:docentral/features/day_closeout/domain/day_closeout_summary.dart';
import 'package:docentral/features/day_closeout/presentation/providers/day_closeout_repository_provider.dart';
import 'package:docentral/features/invoice/domain/payment_method.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'day_closeout_summary_provider.g.dart';

@riverpod
Stream<DayCloseoutSummary> dayCloseoutSummary(Ref ref) {
  final Role? role = ref.watch(currentRoleProvider);
  if (role == null) {
    return Stream.value(
      const DayCloseoutSummary(
        completedVisitsCount: 0,
        paymentTotalsByMethod: <PaymentMethod, double>{},
        newInvoicesTotal: 0,
        outstandingInvoicesCount: 0,
      ),
    );
  }

  return ref
      .watch(dayCloseoutRepositoryProvider)
      .watchSummary(role: role, day: DateTime.now());
}
