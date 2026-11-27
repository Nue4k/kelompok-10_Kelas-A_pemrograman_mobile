import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:creaflow/data/models/enums.dart';
import 'package:creaflow/data/models/task_filter.dart';
import 'package:creaflow/data/repositories/dashboard_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late DashboardRepository repository;
  final now = DateTime(2026, 11, 28, 10, 0);

  Future<void> seedTask({
    required String id,
    required String picMemberId,
    required TaskStatus status,
    required TaskPriority priority,
    DateTime? deadline,
    DateTime? archivedAt,
  }) async {
    await firestore
        .collection('workspaces')
        .doc('ws-1')
        .collection('tasks')
        .doc(id)
        .set({
      'workspaceId': 'ws-1',
      'picMemberId': picMemberId,
      'createdBy': 'pm-1',
      'title': 'Task $id',
      'priority': priority.value,
      'status': status.value,
      'deadline': deadline == null ? null : Timestamp.fromDate(deadline),
      'archivedAt': archivedAt == null ? null : Timestamp.fromDate(archivedAt),
      'createdAt': Timestamp.fromDate(DateTime(2026, 11, 20)),
    });
  }

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    repository = DashboardRepository(firestore: firestore);

    await seedTask(
      id: '1',
      picMemberId: 'u-1',
      status: TaskStatus.todo,
      priority: TaskPriority.high,
      deadline: DateTime(2026, 11, 27), // overdue
    );
    await seedTask(
      id: '2',
      picMemberId: 'u-1',
      status: TaskStatus.inProgress,
      priority: TaskPriority.medium,
      deadline: DateTime(2026, 11, 29, 15, 0), // due tomorrow
    );
    await seedTask(
      id: '3',
      picMemberId: 'u-2',
      status: TaskStatus.done,
      priority: TaskPriority.low,
      deadline: DateTime(2026, 11, 25), // done -> not overdue
    );
    await seedTask(
      id: '4',
      picMemberId: 'u-1',
      status: TaskStatus.todo,
      priority: TaskPriority.high,
      deadline: DateTime(2026, 11, 20),
      archivedAt: DateTime(2026, 11, 26), // archived -> excluded
    );
  });

  group('DashboardRepository', () {
    test('getWorkspaceSummary & watchWorkspaceSummary compute accurate counts',
        () async {
      final summary = await repository.getWorkspaceSummary('ws-1', now: now);
      expect(summary.todoCount, 1);
      expect(summary.inProgressCount, 1);
      expect(summary.doneCount, 1);
      expect(summary.overdueCount, 1);
      expect(summary.dueTomorrowCount, 1);
      expect(summary.totalTasks, 3);

      final u1Summary = await repository.getWorkspaceSummary(
        'ws-1',
        picMemberId: 'u-1',
        now: now,
      );
      expect(u1Summary.totalTasks, 2);
      expect(u1Summary.doneCount, 0);

      final streamed =
          await repository.watchWorkspaceSummary('ws-1', now: now).first;
      expect(streamed, summary);
    });

    test('getFilteredTasks & watchFilteredTasks apply filters and sorting',
        () async {
      final filtered = await repository.getFilteredTasks(
        'ws-1',
        filter: const TaskFilter(
          picMemberId: 'u-1',
          sortBy: TaskSortBy.priorityDesc,
        ),
        now: now,
      );
      expect(filtered.map((t) => t.id), ['1', '2']);

      final overdueOnly = await repository
          .watchFilteredTasks(
            'ws-1',
            filter: const TaskFilter(overdueOnly: true),
            now: now,
          )
          .first;
      expect(overdueOnly.map((t) => t.id), ['1']);
    });
  });
}
