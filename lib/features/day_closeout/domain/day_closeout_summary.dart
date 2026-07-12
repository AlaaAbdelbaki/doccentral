import 'package:docentral/features/invoice/domain/payment_method.dart';

/// Real-time aggregate of a single clinic-day's activity, computed — never
/// stored — from Visits, Payments, and Invoices. See [DayCloseoutRepository].
class DayCloseoutSummary {
  const DayCloseoutSummary({
    required this.completedVisitsCount,
    required this.paymentTotalsByMethod,
    required this.newInvoicesTotal,
    required this.outstandingInvoicesCount,
  });

  final int completedVisitsCount;
  final Map<PaymentMethod, double> paymentTotalsByMethod;
  final double newInvoicesTotal;
  final int outstandingInvoicesCount;

  double get totalPayments =>
      paymentTotalsByMethod.values.fold(0, (double sum, double v) => sum + v);
}
