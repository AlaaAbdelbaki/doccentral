import 'package:docentral/features/invoice/data/payment_repository_impl.dart';
import 'package:docentral/features/invoice/domain/payment_repository.dart';
import 'package:docentral/shared/data/providers/app_database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'payment_repository_provider.g.dart';

@riverpod
PaymentRepository paymentRepository(Ref ref) {
  return PaymentRepositoryImpl(ref.watch(appDatabaseProvider));
}
