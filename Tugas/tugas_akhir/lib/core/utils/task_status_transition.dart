import '../../data/models/enums.dart';

/// Centralized task status transition rules aligned with `firestore.rules`.
abstract final class TaskStatusTransition {
  /// Returns `true` if transitioning from [from] to [to] is allowed for the
  /// given actor roles ([isPm] / [isPic]).
  static bool canTransition({
    required TaskStatus from,
    required TaskStatus to,
    required bool isPm,
    required bool isPic,
  }) {
    if (from == to || (!isPm && !isPic)) {
      return false;
    }

    return switch (from) {
      TaskStatus.todo => to == TaskStatus.inProgress,
      TaskStatus.inProgress => to == TaskStatus.inReview,
      TaskStatus.revision => to == TaskStatus.inProgress,
      TaskStatus.inReview =>
        isPm && (to == TaskStatus.done || to == TaskStatus.revision),
      TaskStatus.done => false,
    };
  }

  /// Returns all valid next [TaskStatus] values from [current] for the given
  /// actor roles ([isPm] / [isPic]).
  static List<TaskStatus> allowedNextStatuses({
    required TaskStatus current,
    required bool isPm,
    required bool isPic,
  }) {
    return TaskStatus.values
        .where(
          (next) => canTransition(
            from: current,
            to: next,
            isPm: isPm,
            isPic: isPic,
          ),
        )
        .toList(growable: false);
  }
}
