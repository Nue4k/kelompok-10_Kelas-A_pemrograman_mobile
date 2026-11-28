import '../../core/utils/deadline_reminder_checker.dart';
import '../../core/utils/firestore_converters.dart';
import 'enums.dart';
import 'task_model.dart';

enum TaskSortBy {
  deadlineAsc,
  deadlineDesc,
  priorityDesc,
  createdAtDesc,
}

/// Filter and sort criteria for workspace task lists.
class TaskFilter {
  const TaskFilter({
    this.status,
    this.priority,
    this.picMemberId,
    this.deadlineFrom,
    this.deadlineTo,
    this.overdueOnly = false,
    this.includeArchived = false,
    this.sortBy = TaskSortBy.deadlineAsc,
  });

  final TaskStatus? status;
  final TaskPriority? priority;
  final String? picMemberId;
  final DateTime? deadlineFrom;
  final DateTime? deadlineTo;
  final bool overdueOnly;
  final bool includeArchived;
  final TaskSortBy sortBy;

  bool get hasActiveFilters =>
      status != null ||
      priority != null ||
      (picMemberId != null && picMemberId!.trim().isNotEmpty) ||
      deadlineFrom != null ||
      deadlineTo != null ||
      overdueOnly ||
      includeArchived;

  TaskFilter copyWith({
    TaskStatus? status,
    bool clearStatus = false,
    TaskPriority? priority,
    bool clearPriority = false,
    String? picMemberId,
    bool clearPicMemberId = false,
    DateTime? deadlineFrom,
    bool clearDeadlineFrom = false,
    DateTime? deadlineTo,
    bool clearDeadlineTo = false,
    bool? overdueOnly,
    bool? includeArchived,
    TaskSortBy? sortBy,
  }) {
    return TaskFilter(
      status: clearStatus ? null : (status ?? this.status),
      priority: clearPriority ? null : (priority ?? this.priority),
      picMemberId: clearPicMemberId ? null : (picMemberId ?? this.picMemberId),
      deadlineFrom:
          clearDeadlineFrom ? null : (deadlineFrom ?? this.deadlineFrom),
      deadlineTo: clearDeadlineTo ? null : (deadlineTo ?? this.deadlineTo),
      overdueOnly: overdueOnly ?? this.overdueOnly,
      includeArchived: includeArchived ?? this.includeArchived,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool matches(TaskModel task, {DateTime? now}) {
    if (!includeArchived && task.isArchived) return false;
    if (status != null && task.status != status) return false;
    if (priority != null && task.priority != priority) return false;

    final trimmedPic = picMemberId?.trim();
    if (trimmedPic != null &&
        trimmedPic.isNotEmpty &&
        task.picMemberId != trimmedPic) {
      return false;
    }

    if (overdueOnly && !DeadlineReminderChecker.isOverdueAt(task, now: now)) {
      return false;
    }

    if (deadlineFrom != null || deadlineTo != null) {
      if (task.deadline == null) return false;
      final dueDate = dateOnly(task.deadline!);
      if (deadlineFrom != null && dueDate.isBefore(dateOnly(deadlineFrom!))) {
        return false;
      }
      if (deadlineTo != null && dueDate.isAfter(dateOnly(deadlineTo!))) {
        return false;
      }
    }

    return true;
  }

  List<TaskModel> apply(Iterable<TaskModel> tasks, {DateTime? now}) {
    final filtered = tasks.where((t) => matches(t, now: now)).toList();
    filtered.sort((a, b) => _compareTasks(a, b, sortBy));
    return filtered;
  }

  static int _compareTasks(TaskModel a, TaskModel b, TaskSortBy sortBy) {
    switch (sortBy) {
      case TaskSortBy.deadlineAsc:
        final cmp = _compareNullableDate(a.deadline, b.deadline, ascending: true);
        return cmp != 0 ? cmp : a.title.compareTo(b.title);
      case TaskSortBy.deadlineDesc:
        final cmp =
            _compareNullableDate(a.deadline, b.deadline, ascending: false);
        return cmp != 0 ? cmp : a.title.compareTo(b.title);
      case TaskSortBy.priorityDesc:
        final pCmp =
            _priorityWeight(b.priority).compareTo(_priorityWeight(a.priority));
        if (pCmp != 0) return pCmp;
        final dCmp =
            _compareNullableDate(a.deadline, b.deadline, ascending: true);
        return dCmp != 0 ? dCmp : a.title.compareTo(b.title);
      case TaskSortBy.createdAtDesc:
        final cmp =
            _compareNullableDate(a.createdAt, b.createdAt, ascending: false);
        return cmp != 0 ? cmp : a.title.compareTo(b.title);
    }
  }

  static int _priorityWeight(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.high => 3,
      TaskPriority.medium => 2,
      TaskPriority.low => 1,
    };
  }

  static int _compareNullableDate(
    DateTime? a,
    DateTime? b, {
    required bool ascending,
  }) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return ascending ? a.compareTo(b) : b.compareTo(a);
  }
}
