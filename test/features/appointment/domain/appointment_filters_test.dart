import 'package:docentral/features/appointment/domain/appointment_filters.dart';
import 'package:docentral/features/appointment/domain/appointment_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppointmentFilters.isActive', () {
    test('is false when no filter is set', () {
      expect(const AppointmentFilters().isActive, isFalse);
    });

    test('is true when any single field is set', () {
      expect(
        const AppointmentFilters(patientNameQuery: 'ami').isActive,
        isTrue,
      );
      expect(
        const AppointmentFilters(status: AppointmentStatus.scheduled).isActive,
        isTrue,
      );
      expect(
        const AppointmentFilters(assignedUserId: 'dentist-1').isActive,
        isTrue,
      );
      expect(
        AppointmentFilters(startDate: DateTime(2026, 6, 1)).isActive,
        isTrue,
      );
    });
  });

  group('AppointmentFilters.matches', () {
    test('matches everything when no filter is set', () {
      const AppointmentFilters filters = AppointmentFilters();
      expect(
        filters.matches(
          'Amine Trabelsi',
          AppointmentStatus.scheduled,
          'dentist-1',
        ),
        isTrue,
      );
    });

    test('filters by case-insensitive patient name substring', () {
      const AppointmentFilters filters = AppointmentFilters(
        patientNameQuery: 'AMI',
      );
      expect(
        filters.matches(
          'Amine Trabelsi',
          AppointmentStatus.scheduled,
          'dentist-1',
        ),
        isTrue,
      );
      expect(
        filters.matches(
          'Sarra Ben Youssef',
          AppointmentStatus.scheduled,
          'dentist-1',
        ),
        isFalse,
      );
    });

    test('filters by exact status', () {
      const AppointmentFilters filters = AppointmentFilters(
        status: AppointmentStatus.checkedIn,
      );
      expect(
        filters.matches(
          'Amine Trabelsi',
          AppointmentStatus.checkedIn,
          'dentist-1',
        ),
        isTrue,
      );
      expect(
        filters.matches(
          'Amine Trabelsi',
          AppointmentStatus.scheduled,
          'dentist-1',
        ),
        isFalse,
      );
    });

    test('filters by exact assigned user', () {
      const AppointmentFilters filters = AppointmentFilters(
        assignedUserId: 'dentist-2',
      );
      expect(
        filters.matches(
          'Amine Trabelsi',
          AppointmentStatus.scheduled,
          'dentist-2',
        ),
        isTrue,
      );
      expect(
        filters.matches(
          'Amine Trabelsi',
          AppointmentStatus.scheduled,
          'dentist-1',
        ),
        isFalse,
      );
    });

    test('composes filters as an intersection (AND)', () {
      const AppointmentFilters filters = AppointmentFilters(
        patientNameQuery: 'amine',
        status: AppointmentStatus.cancelled,
        assignedUserId: 'dentist-1',
      );
      expect(
        filters.matches(
          'Amine Trabelsi',
          AppointmentStatus.cancelled,
          'dentist-1',
        ),
        isTrue,
      );
      // Name matches but status doesn't -> excluded.
      expect(
        filters.matches(
          'Amine Trabelsi',
          AppointmentStatus.scheduled,
          'dentist-1',
        ),
        isFalse,
      );
    });
  });

  group('AppointmentFilters.copyWith', () {
    test('clears a field only when its clear flag is passed', () {
      final AppointmentFilters withDate = AppointmentFilters(
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 7),
      );

      final AppointmentFilters cleared = withDate.copyWith(
        clearStartDate: true,
        clearEndDate: true,
      );
      expect(cleared.startDate, isNull);
      expect(cleared.endDate, isNull);

      final AppointmentFilters unchanged = withDate.copyWith();
      expect(unchanged.startDate, withDate.startDate);
      expect(unchanged.endDate, withDate.endDate);
    });
  });
}
