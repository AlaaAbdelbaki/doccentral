import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'patient_search_query_provider.g.dart';

@riverpod
class PatientSearchQuery extends _$PatientSearchQuery {
  @override
  String build() => '';

  void setQuery(String value) => state = value;
}
