import '../../data/models/enums.dart';
import '../../data/models/task_model.dart';

/// Result of scanning tasks for upcoming H-1 deadlines and overdue items.
class DeadlineReminderResult {
  const DeadlineReminderResult({
    required this.dueTomorrowTasks,
    required this.overdueTasks,
  });

  final List<TaskModel> dueTomorrowTasks;
  final List<TaskModel> overdueTasks;

  bool get hasReminders =>
      dueTomorrowTasks.isNotEmpty || overdueTasks.isNotEmpty;
}

/// Client-side helper to detect H-1 deadlines and overdue tasks.
abstract final class DeadlineReminderChecker {
  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Returns `true` if [task] is active (not done, not archived) and its
  /// deadline falls on tomorrow's calendar date relative to [now].
  static bool isDueTomorrow(TaskModel task, {DateTime? now}) {
    if (task.deadline == null ||
        task.status == TaskStatus.done ||
        task.isArchived) {
      return false;
    }
    final today = _dateOnly(now ?? DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final dueDate = _dateOnly(task.deadline!);
    return dueDate == tomorrow;
  }

  /// Returns `true` if [task] is active (not done, not archived) and its
  /// deadline is strictly before today's calendar date relative to [now].
  static bool isOverdueAt(TaskModel task, {DateTime? now}) {
    if (task.deadline == null ||
        task.status == TaskStatus.done ||
        task.isArchived) {
      return false;
    }
    final today = _dateOnly(now ?? DateTime.now());
    final dueDate = _dateOnly(task.deadline!);
    return dueDate.isBefore(today);
  }

  /// Partitions [tasks] into H-1 (`dueTomorrowTasks`) and `overdueTasks`.
  static DeadlineReminderResult check(
    Iterable<TaskModel> tasks, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final dueTomorrow = <TaskModel>[];
    final overdue = <TaskModel>[];

    for (final task in tasks) {
      if (isDueTomorrow(task, now: reference)) {
        dueTomorrow.add(task);
      } else if (isOverdueAt(task, now: reference)) {
        overdue.add(task);
      }
    }

    return DeadlineReminderResult(
      dueTomorrowTasks: List.unmodifiable(dueTomorrow),
      overdueTasks: List.unmodifiable(overdue),
    );
  }
}
