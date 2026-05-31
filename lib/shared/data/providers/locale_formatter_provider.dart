import 'package:docentral/shared/data/providers/locale_provider.dart';
import 'package:docentral/shared/services/locale_formatter_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_formatter_provider.g.dart';

@riverpod
LocaleFormatterService localeFormatter(Ref ref) {
  final locale = ref.watch(appLocaleProvider);
  return LocaleFormatterService(locale);
}
