import 'package:docentral/features/invoice/data/invoice_repository_impl.dart';
import 'package:docentral/features/invoice/domain/invoice_repository.dart';
import 'package:docentral/shared/data/providers/app_database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'invoice_repository_provider.g.dart';

@riverpod
InvoiceRepository invoiceRepository(Ref ref) {
  return InvoiceRepositoryImpl(ref.watch(appDatabaseProvider));
}
