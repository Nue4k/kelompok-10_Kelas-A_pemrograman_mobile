import 'package:creaflow/core/utils/deadline_reminder_checker.dart';
import 'package:creaflow/data/models/enums.dart';
import 'package:creaflow/data/models/task_model.dart';
import 'package:flutter_test/flutter_test.dart';

TaskModel _task({
  required String id,
  DateTime? deadline,
  TaskStatus status = TaskStatus.todo,
  DateTime? archivedAt,
}) {
  return TaskModel(
    id: id,
    workspaceId: 'ws-1',
    picMemberId: 'u2',
    createdBy: 'u1',
    title: 'Task $id',
    deadline: deadline,
    priority: TaskPriority.medium,
    status: status,
    archivedAt: archivedAt,
  );
}

void main() {
  group('DeadlineReminderChecker', () {
    final now = DateTime(2026, 11, 27, 14, 0);

    test('identifies H-1 (due tomorrow) and overdue tasks accurately', () {
      final yesterday = _task(id: 'overdue', deadline: DateTime(2026, 11, 26));
      final today = _task(id: 'today', deadline: DateTime(2026, 11, 27));
      final tomorrow = _task(id: 'tomorrow', deadline: DateTime(2026, 11, 28, 23, 59));
      final later = _task(id: 'later', deadline: DateTime(2026, 11, 29));
      final done = _task(
        id: 'done',
        deadline: DateTime(2026, 11, 28),
        status: TaskStatus.done,
      );
      final archived = _task(
        id: 'archived',
        deadline: DateTime(2026, 11, 26),
        archivedAt: DateTime(2026, 11, 25),
      );
      final noDeadline = _task(id: 'no-deadline');

      expect(DeadlineReminderChecker.isDueTomorrow(tomorrow, now: now), isTrue);
      expect(DeadlineReminderChecker.isDueTomorrow(today, now: now), isFalse);
      expect(DeadlineReminderChecker.isDueTomorrow(later, now: now), isFalse);
      expect(DeadlineReminderChecker.isDueTomorrow(done, now: now), isFalse);

      expect(DeadlineReminderChecker.isOverdueAt(yesterday, now: now), isTrue);
      expect(DeadlineReminderChecker.isOverdueAt(today, now: now), isFalse);
      expect(DeadlineReminderChecker.isOverdueAt(archived, now: now), isFalse);

      final result = DeadlineReminderChecker.check(
        [yesterday, today, tomorrow, later, done, archived, noDeadline],
        now: now,
      );

      expect(result.hasReminders, isTrue);
      expect(result.dueTomorrowTasks.map((t) => t.id), ['tomorrow']);
      expect(result.overdueTasks.map((t) => t.id), ['overdue']);
    });
  });
}
