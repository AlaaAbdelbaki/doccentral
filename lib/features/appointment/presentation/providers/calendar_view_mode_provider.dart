import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calendar_view_mode_provider.g.dart';

enum CalendarViewMode { day, week }

@riverpod
class CalendarViewModeController extends _$CalendarViewModeController {
  @override
  CalendarViewMode build() => CalendarViewMode.day;

  void setMode(CalendarViewMode mode) => state = mode;
}
