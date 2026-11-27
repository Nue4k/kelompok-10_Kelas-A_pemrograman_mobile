import 'package:creaflow/core/exceptions/task_exception.dart';
import 'package:creaflow/data/models/task_filter.dart';
import 'package:creaflow/services/dashboard_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardService.validateFilter', () {
    test('accepts empty, single-bound, equal, and valid date ranges', () {
      expect(() => DashboardService.validateFilter(const TaskFilter()),
          returnsNormally);

      expect(
        () => DashboardService.validateFilter(
          TaskFilter(deadlineFrom: DateTime(2026, 11, 20)),
        ),
        returnsNormally,
      );

      expect(
        () => DashboardService.validateFilter(
          TaskFilter(
            deadlineFrom: DateTime(2026, 11, 20, 18, 0),
            deadlineTo: DateTime(2026, 11, 20, 8, 0),
          ),
        ),
        returnsNormally,
      );

      expect(
        () => DashboardService.validateFilter(
          TaskFilter(
            deadlineFrom: DateTime(2026, 11, 20),
            deadlineTo: DateTime(2026, 11, 25),
          ),
        ),
        returnsNormally,
      );
    });

    test('throws invalid-date-range when deadlineTo is before deadlineFrom',
        () {
      expect(
        () => DashboardService.validateFilter(
          TaskFilter(
            deadlineFrom: DateTime(2026, 11, 25),
            deadlineTo: DateTime(2026, 11, 20),
          ),
        ),
        throwsA(
          isA<TaskException>().having(
            (e) => e.code,
            'code',
            'invalid-date-range',
          ),
        ),
      );
    });
  });
}
