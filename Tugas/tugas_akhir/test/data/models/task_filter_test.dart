import 'package:creaflow/data/models/enums.dart';
import 'package:creaflow/data/models/task_filter.dart';
import 'package:creaflow/data/models/task_model.dart';
import 'package:flutter_test/flutter_test.dart';

TaskModel _task({
  required String id,
  String title = '',
  String picMemberId = 'u1',
  TaskPriority priority = TaskPriority.medium,
  TaskStatus status = TaskStatus.todo,
  DateTime? deadline,
  DateTime? archivedAt,
  DateTime? createdAt,
}) {
  return TaskModel(
    id: id,
    workspaceId: 'ws-1',
    picMemberId: picMemberId,
    createdBy: 'pm-1',
    title: title.isEmpty ? 'Task $id' : title,
    priority: priority,
    status: status,
    deadline: deadline,
    archivedAt: archivedAt,
    createdAt: createdAt,
  );
}

void main() {
  group('TaskFilter', () {
    final now = DateTime(2026, 11, 28, 12, 0);

    final sampleTasks = [
      _task(
        id: '1',
        title: 'Alpha',
        picMemberId: 'u1',
        priority: TaskPriority.high,
        status: TaskStatus.todo,
        deadline: DateTime(2026, 11, 27), // overdue
        createdAt: DateTime(2026, 11, 20),
      ),
      _task(
        id: '2',
        title: 'Beta',
        picMemberId: 'u2',
        priority: TaskPriority.low,
        status: TaskStatus.inProgress,
        deadline: DateTime(2026, 11, 30),
        createdAt: DateTime(2026, 11, 22),
      ),
      _task(
        id: '3',
        title: 'Gamma',
        picMemberId: 'u1',
        priority: TaskPriority.medium,
        status: TaskStatus.done,
        deadline: DateTime(2026, 11, 25),
        createdAt: DateTime(2026, 11, 24),
      ),
      _task(
        id: '4',
        title: 'Delta',
        picMemberId: 'u1',
        priority: TaskPriority.high,
        status: TaskStatus.todo,
        deadline: null,
        createdAt: null,
      ),
      _task(
        id: '5',
        title: 'Archived',
        picMemberId: 'u1',
        priority: TaskPriority.high,
        status: TaskStatus.todo,
        deadline: DateTime(2026, 11, 29),
        archivedAt: DateTime(2026, 11, 26),
      ),
    ];

    test('default filter excludes archived and sorts deadlineAsc', () {
      const filter = TaskFilter();
      expect(filter.hasActiveFilters, isFalse);

      final result = filter.apply(sampleTasks, now: now);
      expect(result.map((t) => t.id), ['3', '1', '2', '4']);
    });

    test('filters by status, priority, and picMemberId (trimmed)', () {
      const filter = TaskFilter(
        status: TaskStatus.todo,
        priority: TaskPriority.high,
        picMemberId: ' u1 ',
      );
      expect(filter.hasActiveFilters, isTrue);

      final result = filter.apply(sampleTasks, now: now);
      expect(result.map((t) => t.id), ['1', '4']);
    });

    test('filters by inclusive date-only deadline range and excludes null', () {
      final filter = TaskFilter(
        deadlineFrom: DateTime(2026, 11, 27, 23, 0),
        deadlineTo: DateTime(2026, 11, 30, 1, 0),
      );

      final result = filter.apply(sampleTasks, now: now);
      expect(result.map((t) => t.id), ['1', '2']);
    });

    test('filters overdueOnly and includeArchived', () {
      const overdueFilter = TaskFilter(overdueOnly: true);
      expect(
        overdueFilter.apply(sampleTasks, now: now).map((t) => t.id),
        ['1'],
      );

      const archivedFilter = TaskFilter(includeArchived: true);
      expect(
        archivedFilter.apply(sampleTasks, now: now).map((t) => t.id),
        contains('5'),
      );
    });

    test('supports all TaskSortBy modes', () {
      final descDeadline = const TaskFilter(sortBy: TaskSortBy.deadlineDesc)
          .apply(sampleTasks, now: now);
      expect(descDeadline.map((t) => t.id), ['2', '1', '3', '4']);

      final priorityDesc = const TaskFilter(sortBy: TaskSortBy.priorityDesc)
          .apply(sampleTasks, now: now);
      expect(priorityDesc.map((t) => t.id), ['1', '4', '3', '2']);

      final createdAtDesc = const TaskFilter(sortBy: TaskSortBy.createdAtDesc)
          .apply(sampleTasks, now: now);
      expect(createdAtDesc.map((t) => t.id), ['3', '2', '1', '4']);
    });

    test('copyWith and clear flags work properly', () {
      final f1 = TaskFilter(
        status: TaskStatus.todo,
        priority: TaskPriority.high,
        picMemberId: 'u1',
        deadlineFrom: DateTime(2026, 11, 1),
        deadlineTo: DateTime(2026, 11, 30),
      );

      final f2 = f1.copyWith(
        clearStatus: true,
        clearPriority: true,
        clearPicMemberId: true,
        clearDeadlineFrom: true,
        clearDeadlineTo: true,
      );

      expect(f2.status, isNull);
      expect(f2.priority, isNull);
      expect(f2.picMemberId, isNull);
      expect(f2.deadlineFrom, isNull);
      expect(f2.deadlineTo, isNull);
      expect(f2.hasActiveFilters, isFalse);
    });
  });
}
