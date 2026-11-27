import 'package:creaflow/data/models/dashboard_summary_model.dart';
import 'package:creaflow/data/models/enums.dart';
import 'package:creaflow/data/models/task_model.dart';
import 'package:flutter_test/flutter_test.dart';

TaskModel _task({
  required String id,
  required TaskStatus status,
  DateTime? deadline,
  DateTime? archivedAt,
}) {
  return TaskModel(
    id: id,
    workspaceId: 'ws-1',
    picMemberId: 'user-1',
    createdBy: 'pm-1',
    title: 'Task $id',
    priority: TaskPriority.medium,
    status: status,
    deadline: deadline,
    archivedAt: archivedAt,
  );
}

void main() {
  group('DashboardSummaryModel', () {
    final now = DateTime(2026, 11, 28, 10, 0);

    test('empty list yields zero counts and zero completionRate', () {
      final summary = DashboardSummaryModel.fromTasks(const [], now: now);

      expect(summary.todoCount, 0);
      expect(summary.inProgressCount, 0);
      expect(summary.inReviewCount, 0);
      expect(summary.revisionCount, 0);
      expect(summary.doneCount, 0);
      expect(summary.overdueCount, 0);
      expect(summary.dueTomorrowCount, 0);
      expect(summary.totalTasks, 0);
      expect(summary.activeTasks, 0);
      expect(summary.completionRate, 0.0);
    });

    test('computes status counts, overdue, H-1, and excludes archived', () {
      final tasks = [
        _task(
          id: '1',
          status: TaskStatus.todo,
          deadline: DateTime(2026, 11, 27), // overdue
        ),
        _task(
          id: '2',
          status: TaskStatus.inProgress,
          deadline: DateTime(2026, 11, 29, 23, 59), // due tomorrow (H-1)
        ),
        _task(
          id: '3',
          status: TaskStatus.inReview,
          deadline: DateTime(2026, 12, 2),
        ),
        _task(
          id: '4',
          status: TaskStatus.revision,
          deadline: DateTime(2026, 11, 25), // overdue
        ),
        _task(
          id: '5',
          status: TaskStatus.done,
          deadline: DateTime(2026, 11, 20), // done -> not overdue
        ),
        _task(
          id: '6',
          status: TaskStatus.todo,
          deadline: DateTime(2026, 11, 20),
          archivedAt: DateTime(2026, 11, 26), // archived -> ignored
        ),
      ];

      final summary = DashboardSummaryModel.fromTasks(tasks, now: now);

      expect(summary.todoCount, 1);
      expect(summary.inProgressCount, 1);
      expect(summary.inReviewCount, 1);
      expect(summary.revisionCount, 1);
      expect(summary.doneCount, 1);
      expect(summary.overdueCount, 2);
      expect(summary.dueTomorrowCount, 1);
      expect(summary.totalTasks, 5);
      expect(summary.activeTasks, 4);
      expect(summary.completionRate, closeTo(0.2, 0.0001));

      expect(summary.countByStatus(TaskStatus.todo), 1);
      expect(summary.countByStatus(TaskStatus.inProgress), 1);
      expect(summary.countByStatus(TaskStatus.inReview), 1);
      expect(summary.countByStatus(TaskStatus.revision), 1);
      expect(summary.countByStatus(TaskStatus.done), 1);
    });
  });
}
