import 'package:creaflow/core/utils/task_status_transition.dart';
import 'package:creaflow/data/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskStatusTransition', () {
    test('allows valid transitions for PIC', () {
      expect(
        TaskStatusTransition.canTransition(
          from: TaskStatus.todo,
          to: TaskStatus.inProgress,
          isPm: false,
          isPic: true,
        ),
        isTrue,
      );
      expect(
        TaskStatusTransition.canTransition(
          from: TaskStatus.inProgress,
          to: TaskStatus.inReview,
          isPm: false,
          isPic: true,
        ),
        isTrue,
      );
      expect(
        TaskStatusTransition.canTransition(
          from: TaskStatus.revision,
          to: TaskStatus.inProgress,
          isPm: false,
          isPic: true,
        ),
        isTrue,
      );
    });

    test('blocks PIC from approving, requesting revision, or skipping steps', () {
      expect(
        TaskStatusTransition.canTransition(
          from: TaskStatus.inReview,
          to: TaskStatus.done,
          isPm: false,
          isPic: true,
        ),
        isFalse,
      );
      expect(
        TaskStatusTransition.canTransition(
          from: TaskStatus.inReview,
          to: TaskStatus.revision,
          isPm: false,
          isPic: true,
        ),
        isFalse,
      );
      expect(
        TaskStatusTransition.canTransition(
          from: TaskStatus.revision,
          to: TaskStatus.inReview,
          isPm: false,
          isPic: true,
        ),
        isFalse,
      );
    });

    test('allows PM to approve or request revision from inReview', () {
      expect(
        TaskStatusTransition.canTransition(
          from: TaskStatus.inReview,
          to: TaskStatus.done,
          isPm: true,
          isPic: false,
        ),
        isTrue,
      );
      expect(
        TaskStatusTransition.canTransition(
          from: TaskStatus.inReview,
          to: TaskStatus.revision,
          isPm: true,
          isPic: false,
        ),
        isTrue,
      );
    });

    test('rejects transitions from done, same-status, and unauthorized actors', () {
      for (final next in TaskStatus.values) {
        expect(
          TaskStatusTransition.canTransition(
            from: TaskStatus.done,
            to: next,
            isPm: true,
            isPic: true,
          ),
          isFalse,
        );
      }

      expect(
        TaskStatusTransition.canTransition(
          from: TaskStatus.todo,
          to: TaskStatus.inProgress,
          isPm: false,
          isPic: false,
        ),
        isFalse,
      );
    });

    test('allowedNextStatuses returns expected options by role', () {
      expect(
        TaskStatusTransition.allowedNextStatuses(
          current: TaskStatus.inReview,
          isPm: true,
          isPic: false,
        ),
        [TaskStatus.revision, TaskStatus.done],
      );
      expect(
        TaskStatusTransition.allowedNextStatuses(
          current: TaskStatus.inReview,
          isPm: false,
          isPic: true,
        ),
        isEmpty,
      );
    });
  });
}
