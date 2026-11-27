import 'package:creaflow/core/exceptions/task_exception.dart';
import 'package:creaflow/data/models/enums.dart';
import 'package:creaflow/services/task_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskService validation', () {
    test('validateTitle trims valid title and rejects empty or too long', () {
      expect(TaskService.validateTitle('  Buat API  '), 'Buat API');

      expect(
        () => TaskService.validateTitle('   '),
        throwsA(
          isA<TaskException>().having((e) => e.code, 'code', 'invalid-title'),
        ),
      );

      final tooLong = 'a' * (TaskService.maxTitleLength + 1);
      expect(
        () => TaskService.validateTitle(tooLong),
        throwsA(
          isA<TaskException>().having((e) => e.code, 'code', 'invalid-title'),
        ),
      );
    });

    test('validateDescription normalizes blank to null and rejects too long', () {
      expect(TaskService.validateDescription(null), isNull);
      expect(TaskService.validateDescription('   '), isNull);
      expect(TaskService.validateDescription('  Detail tugas  '), 'Detail tugas');

      final tooLong = 'a' * (TaskService.maxDescriptionLength + 1);
      expect(
        () => TaskService.validateDescription(tooLong),
        throwsA(
          isA<TaskException>()
              .having((e) => e.code, 'code', 'invalid-description'),
        ),
      );
    });

    test('validateDateRange allows valid ranges and rejects deadline before start', () {
      final start = DateTime(2026, 11, 20);
      final sameDay = DateTime(2026, 11, 20);
      final later = DateTime(2026, 11, 25);
      final earlier = DateTime(2026, 11, 19);

      TaskService.validateDateRange(startDate: start, deadline: sameDay);
      TaskService.validateDateRange(startDate: start, deadline: later);
      TaskService.validateDateRange(startDate: null, deadline: earlier);

      expect(
        () => TaskService.validateDateRange(startDate: start, deadline: earlier),
        throwsA(
          isA<TaskException>()
              .having((e) => e.code, 'code', 'invalid-date-range'),
        ),
      );
    });

    test('validateStatusTransition throws TaskException on invalid transition', () {
      TaskService.validateStatusTransition(
        from: TaskStatus.todo,
        to: TaskStatus.inProgress,
        isPm: false,
        isPic: true,
      );

      expect(
        () => TaskService.validateStatusTransition(
          from: TaskStatus.inReview,
          to: TaskStatus.done,
          isPm: false,
          isPic: true,
        ),
        throwsA(
          isA<TaskException>()
              .having((e) => e.code, 'code', 'invalid-status-transition'),
        ),
      );
    });
  });
}
