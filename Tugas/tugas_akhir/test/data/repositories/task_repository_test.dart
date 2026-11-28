import 'package:creaflow/data/models/enums.dart';
import 'package:creaflow/data/repositories/task_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late TaskRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = TaskRepository(firestore: firestore);
  });

  group('TaskRepository', () {
    test('createTask, getTask, updateTask, archiveTask, unarchiveTask',
        () async {
      final created = await repository.createTask(
        workspaceId: 'ws-1',
        picMemberId: 'u-1',
        createdBy: 'pm-1',
        title: 'Buat API',
        description: 'Endpoint auth',
        priority: TaskPriority.high,
        deadline: DateTime(2026, 12, 1),
      );

      expect(created.status, TaskStatus.todo);
      expect(created.priority, TaskPriority.high);

      final fetched = await repository.getTask('ws-1', created.id);
      expect(fetched?.title, 'Buat API');

      await repository.updateTask(
        workspaceId: 'ws-1',
        taskId: created.id,
        title: 'Buat API v2',
        clearDescription: true,
        clearDeadline: true,
        priority: TaskPriority.low,
      );

      final updated = await repository.getTask('ws-1', created.id);
      expect(updated!.title, 'Buat API v2');
      expect(updated.description, isNull);
      expect(updated.deadline, isNull);
      expect(updated.priority, TaskPriority.low);

      await repository.archiveTask(workspaceId: 'ws-1', taskId: created.id);
      expect(await repository.getTasks('ws-1'), isEmpty);
      expect(
        await repository.getTasks('ws-1', includeArchived: true),
        hasLength(1),
      );

      await repository.unarchiveTask(workspaceId: 'ws-1', taskId: created.id);
      expect(await repository.getTasks('ws-1'), hasLength(1));
    });
  });
}
