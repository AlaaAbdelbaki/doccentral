import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calendar_week_anchor_provider.g.dart';

/// Monday of the week currently displayed by the week view.
@riverpod
class CalendarWeekAnchor extends _$CalendarWeekAnchor {
  @override
  DateTime build() {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: today.weekday - 1));
  }

  void next() => state = state.add(const Duration(days: 7));

  void previous() => state = state.subtract(const Duration(days: 7));
}
