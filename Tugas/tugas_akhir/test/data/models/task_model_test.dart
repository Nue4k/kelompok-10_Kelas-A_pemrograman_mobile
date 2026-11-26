import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:creaflow/data/models/enums.dart';
import 'package:creaflow/data/models/task_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskModel', () {
    test('fromMap and toMap round-trip with Timestamp dates', () {
      final start = DateTime(2026, 11, 20);
      final deadline = DateTime(2026, 11, 30);
      final created = DateTime(2026, 11, 19, 10, 30);

      final model = TaskModel(
        id: 'task-1',
        workspaceId: 'ws-1',
        picMemberId: 'user-2',
        createdBy: 'user-1',
        title: 'Implement auth',
        description: 'Setup email/password login',
        startDate: start,
        deadline: deadline,
        priority: TaskPriority.high,
        status: TaskStatus.inProgress,
        createdAt: created,
        updatedAt: created,
      );

      final map = model.toMap();
      expect(map['startDate'], isA<Timestamp>());
      expect(map['priority'], 'high');
      expect(map['status'], 'in_progress');
      expect(map.containsKey('id'), isFalse);

      final restored = TaskModel.fromMap('task-1', map);
      expect(restored.id, 'task-1');
      expect(restored.workspaceId, 'ws-1');
      expect(restored.picMemberId, 'user-2');
      expect(restored.title, 'Implement auth');
      expect(restored.startDate, start);
      expect(restored.deadline, deadline);
      expect(restored.priority, TaskPriority.high);
      expect(restored.status, TaskStatus.inProgress);
    });

    test('isOverdue behaves correctly for past deadline, done, and archived', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      final overdueTask = TaskModel(
        id: 't1',
        workspaceId: 'ws-1',
        picMemberId: 'u2',
        createdBy: 'u1',
        title: 'Late task',
        deadline: yesterday,
        priority: TaskPriority.medium,
        status: TaskStatus.todo,
      );
      expect(overdueTask.isOverdue, isTrue);

      final doneTask = TaskModel(
        id: 't2',
        workspaceId: 'ws-1',
        picMemberId: 'u2',
        createdBy: 'u1',
        title: 'Done task',
        deadline: yesterday,
        priority: TaskPriority.medium,
        status: TaskStatus.done,
      );
      expect(doneTask.isOverdue, isFalse);

      final archivedTask = TaskModel(
        id: 't3',
        workspaceId: 'ws-1',
        picMemberId: 'u2',
        createdBy: 'u1',
        title: 'Archived task',
        deadline: yesterday,
        priority: TaskPriority.medium,
        status: TaskStatus.todo,
        archivedAt: DateTime.now(),
      );
      expect(archivedTask.isOverdue, isFalse);
      expect(archivedTask.isArchived, isTrue);
    });
  });
}
