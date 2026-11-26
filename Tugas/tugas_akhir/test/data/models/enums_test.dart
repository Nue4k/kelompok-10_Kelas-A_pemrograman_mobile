import 'package:creaflow/data/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Enums', () {
    test('TaskStatus fromValue round-trips all values', () {
      for (final status in TaskStatus.values) {
        expect(TaskStatus.fromValue(status.value), status);
      }
      expect(TaskStatus.fromValue('in_progress'), TaskStatus.inProgress);
    });

    test('unknown values fall back to defaults', () {
      expect(TaskStatus.fromValue('unknown'), TaskStatus.todo);
      expect(TaskPriority.fromValue('unknown'), TaskPriority.medium);
      expect(MemberRole.fromValue('unknown'), MemberRole.member);
      expect(RequestStatus.fromValue('unknown'), RequestStatus.pending);
    });

    test('ReviewDecision.fromValue returns null for null or unknown', () {
      expect(ReviewDecision.fromValue(null), isNull);
      expect(ReviewDecision.fromValue('unknown'), isNull);
      expect(ReviewDecision.fromValue('approved'), ReviewDecision.approved);
    });
  });
}
