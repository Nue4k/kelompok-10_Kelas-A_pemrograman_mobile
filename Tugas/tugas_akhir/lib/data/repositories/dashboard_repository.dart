import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_collections.dart';
import '../../core/utils/firestore_converters.dart';
import '../models/dashboard_summary_model.dart';
import '../models/enums.dart';
import '../models/task_filter.dart';
import '../models/task_model.dart';

/// Repository for dashboard aggregation queries (`count()`) and filtered task
/// queries under `workspaces/{workspaceId}/tasks`.
class DashboardRepository {
  DashboardRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const List<String> _nonDoneStatuses = [
    'todo',
    'in_progress',
    'in_review',
    'revision',
  ];

  CollectionReference<Map<String, dynamic>> _tasksRef(String workspaceId) =>
      _firestore
          .collection(FirestoreCollections.workspaces)
          .doc(workspaceId)
          .collection(FirestoreCollections.tasks);

  /// Fetches aggregated task counts for a workspace using Firestore `count()`.
  ///
  /// When [picMemberId] is provided, counts are scoped to that PIC.
  Future<DashboardSummaryModel> getWorkspaceSummary(
    String workspaceId, {
    String? picMemberId,
    DateTime? now,
  }) async {
    Query<Map<String, dynamic>> base =
        _tasksRef(workspaceId).where('archivedAt', isNull: true);

    final trimmedPic = picMemberId?.trim();
    if (trimmedPic != null && trimmedPic.isNotEmpty) {
      base = base.where('picMemberId', isEqualTo: trimmedPic);
    }

    final ref = now ?? DateTime.now();
    final startOfToday = dateOnly(ref);
    final startOfTomorrow = startOfToday.add(const Duration(days: 1));
    final startOfDayAfterTomorrow = startOfToday.add(const Duration(days: 2));

    final results = await Future.wait<AggregateQuerySnapshot>([
      base.where('status', isEqualTo: TaskStatus.todo.value).count().get(),
      base
          .where('status', isEqualTo: TaskStatus.inProgress.value)
          .count()
          .get(),
      base.where('status', isEqualTo: TaskStatus.inReview.value).count().get(),
      base.where('status', isEqualTo: TaskStatus.revision.value).count().get(),
      base.where('status', isEqualTo: TaskStatus.done.value).count().get(),
      base
          .where('status', whereIn: _nonDoneStatuses)
          .where('deadline', isLessThan: Timestamp.fromDate(startOfToday))
          .count()
          .get(),
      base
          .where('status', whereIn: _nonDoneStatuses)
          .where(
            'deadline',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfTomorrow),
          )
          .where(
            'deadline',
            isLessThan: Timestamp.fromDate(startOfDayAfterTomorrow),
          )
          .count()
          .get(),
    ]);

    return DashboardSummaryModel(
      todoCount: results[0].count ?? 0,
      inProgressCount: results[1].count ?? 0,
      inReviewCount: results[2].count ?? 0,
      revisionCount: results[3].count ?? 0,
      doneCount: results[4].count ?? 0,
      overdueCount: results[5].count ?? 0,
      dueTomorrowCount: results[6].count ?? 0,
    );
  }

  /// Watches active tasks in a workspace and computes [DashboardSummaryModel]
  /// in real time.
  Stream<DashboardSummaryModel> watchWorkspaceSummary(
    String workspaceId, {
    String? picMemberId,
    DateTime? now,
  }) {
    Query<Map<String, dynamic>> query =
        _tasksRef(workspaceId).where('archivedAt', isNull: true);

    final trimmedPic = picMemberId?.trim();
    if (trimmedPic != null && trimmedPic.isNotEmpty) {
      query = query.where('picMemberId', isEqualTo: trimmedPic);
    }

    return query.snapshots().map((snap) {
      final tasks = snap.docs.map(TaskModel.fromFirestore);
      return DashboardSummaryModel.fromTasks(tasks, now: now);
    });
  }

  /// Fetches tasks matching [filter] using an indexed Firestore query plus
  /// client-side refinement/sorting.
  Future<List<TaskModel>> getFilteredTasks(
    String workspaceId, {
    TaskFilter filter = const TaskFilter(),
    DateTime? now,
  }) async {
    final snap = await _buildFilteredQuery(workspaceId, filter).get();
    final tasks = snap.docs.map(TaskModel.fromFirestore);
    return filter.apply(tasks, now: now);
  }

  /// Watches tasks matching [filter] in real time.
  Stream<List<TaskModel>> watchFilteredTasks(
    String workspaceId, {
    TaskFilter filter = const TaskFilter(),
    DateTime? now,
  }) {
    return _buildFilteredQuery(workspaceId, filter).snapshots().map((snap) {
      final tasks = snap.docs.map(TaskModel.fromFirestore);
      return filter.apply(tasks, now: now);
    });
  }

  Query<Map<String, dynamic>> _buildFilteredQuery(
    String workspaceId,
    TaskFilter filter,
  ) {
    if (filter.includeArchived) {
      return _tasksRef(workspaceId);
    }

    Query<Map<String, dynamic>> query =
        _tasksRef(workspaceId).where('archivedAt', isNull: true);

    final pic = filter.picMemberId?.trim();
    final hasPic = pic != null && pic.isNotEmpty;

    if (hasPic && filter.status != null) {
      query = query
          .where('picMemberId', isEqualTo: pic)
          .where('status', isEqualTo: filter.status!.value);
    } else if (hasPic) {
      query = query.where('picMemberId', isEqualTo: pic);
    } else if (filter.status != null) {
      query = query.where('status', isEqualTo: filter.status!.value);
    } else if (filter.priority != null) {
      query = query.where('priority', isEqualTo: filter.priority!.value);
    }

    if (filter.deadlineFrom != null) {
      query = query.where(
        'deadline',
        isGreaterThanOrEqualTo:
            Timestamp.fromDate(dateOnly(filter.deadlineFrom!)),
      );
    }
    if (filter.deadlineTo != null) {
      final exclusiveEnd = dateOnly(filter.deadlineTo!).add(
        const Duration(days: 1),
      );
      query = query.where(
        'deadline',
        isLessThan: Timestamp.fromDate(exclusiveEnd),
      );
    }

    return query;
  }
}
