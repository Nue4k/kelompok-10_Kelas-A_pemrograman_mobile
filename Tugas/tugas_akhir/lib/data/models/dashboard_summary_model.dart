import '../../core/utils/deadline_reminder_checker.dart';
import 'enums.dart';
import 'task_model.dart';

/// Aggregated task counts for a workspace dashboard (active / non-archived tasks).
class DashboardSummaryModel {
  const DashboardSummaryModel({
    this.todoCount = 0,
    this.inProgressCount = 0,
    this.inReviewCount = 0,
    this.revisionCount = 0,
    this.doneCount = 0,
    this.overdueCount = 0,
    this.dueTomorrowCount = 0,
  });

  final int todoCount;
  final int inProgressCount;
  final int inReviewCount;
  final int revisionCount;
  final int doneCount;
  final int overdueCount;
  final int dueTomorrowCount;

  int get totalTasks =>
      todoCount +
      inProgressCount +
      inReviewCount +
      revisionCount +
      doneCount;

  int get activeTasks => totalTasks - doneCount;

  double get completionRate => totalTasks == 0 ? 0.0 : doneCount / totalTasks;

  int countByStatus(TaskStatus status) {
    return switch (status) {
      TaskStatus.todo => todoCount,
      TaskStatus.inProgress => inProgressCount,
      TaskStatus.inReview => inReviewCount,
      TaskStatus.revision => revisionCount,
      TaskStatus.done => doneCount,
    };
  }

  /// Computes a [DashboardSummaryModel] from an iterable of tasks in memory.
  /// Archived tasks are excluded.
  factory DashboardSummaryModel.fromTasks(
    Iterable<TaskModel> tasks, {
    DateTime? now,
  }) {
    var todo = 0;
    var inProgress = 0;
    var inReview = 0;
    var revision = 0;
    var done = 0;
    var overdue = 0;
    var dueTomorrow = 0;

    final reference = now ?? DateTime.now();

    for (final task in tasks) {
      if (task.isArchived) continue;

      switch (task.status) {
        case TaskStatus.todo:
          todo++;
        case TaskStatus.inProgress:
          inProgress++;
        case TaskStatus.inReview:
          inReview++;
        case TaskStatus.revision:
          revision++;
        case TaskStatus.done:
          done++;
      }

      if (DeadlineReminderChecker.isOverdueAt(task, now: reference)) {
        overdue++;
      } else if (DeadlineReminderChecker.isDueTomorrow(task, now: reference)) {
        dueTomorrow++;
      }
    }

    return DashboardSummaryModel(
      todoCount: todo,
      inProgressCount: inProgress,
      inReviewCount: inReview,
      revisionCount: revision,
      doneCount: done,
      overdueCount: overdue,
      dueTomorrowCount: dueTomorrow,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DashboardSummaryModel &&
        other.todoCount == todoCount &&
        other.inProgressCount == inProgressCount &&
        other.inReviewCount == inReviewCount &&
        other.revisionCount == revisionCount &&
        other.doneCount == doneCount &&
        other.overdueCount == overdueCount &&
        other.dueTomorrowCount == dueTomorrowCount;
  }

  @override
  int get hashCode => Object.hash(
        todoCount,
        inProgressCount,
        inReviewCount,
        revisionCount,
        doneCount,
        overdueCount,
        dueTomorrowCount,
      );

  @override
  String toString() {
    return 'DashboardSummaryModel('
        'todo: $todoCount, '
        'inProgress: $inProgressCount, '
        'inReview: $inReviewCount, '
        'revision: $revisionCount, '
        'done: $doneCount, '
        'overdue: $overdueCount, '
        'dueTomorrow: $dueTomorrowCount)';
  }
}
