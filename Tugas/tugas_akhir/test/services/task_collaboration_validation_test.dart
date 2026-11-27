import 'package:creaflow/core/exceptions/task_exception.dart';
import 'package:creaflow/data/models/enums.dart';
import 'package:creaflow/services/task_collaboration_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskCollaborationService validation', () {
    test('validateCommentText trims valid text and rejects empty or too long', () {
      expect(
        TaskCollaborationService.validateCommentText('  Sudah dicek ya  '),
        'Sudah dicek ya',
      );

      expect(
        () => TaskCollaborationService.validateCommentText('   '),
        throwsA(
          isA<TaskException>().having((e) => e.code, 'code', 'invalid-comment'),
        ),
      );

      final tooLong = 'a' * (TaskCollaborationService.maxCommentLength + 1);
      expect(
        () => TaskCollaborationService.validateCommentText(tooLong),
        throwsA(
          isA<TaskException>().having((e) => e.code, 'code', 'invalid-comment'),
        ),
      );
    });

    test('validateAttachmentUrl accepts http/https URLs and rejects invalid', () {
      expect(
        TaskCollaborationService.validateAttachmentUrl(
          '  https://res.cloudinary.com/demo/image/upload/sample.png  ',
        ),
        'https://res.cloudinary.com/demo/image/upload/sample.png',
      );

      for (final bad in ['', 'ftp://example.com/a.png', 'not-a-url', 'https://']) {
        expect(
          () => TaskCollaborationService.validateAttachmentUrl(bad),
          throwsA(
            isA<TaskException>()
                .having((e) => e.code, 'code', 'invalid-attachment-url'),
          ),
        );
      }
    });

    test('validateReviewFeedback requires feedback for revision only', () {
      expect(
        TaskCollaborationService.validateReviewFeedback(
          null,
          decision: ReviewDecision.approved,
        ),
        isNull,
      );
      expect(
        TaskCollaborationService.validateReviewFeedback(
          '  Bagus  ',
          decision: ReviewDecision.approved,
        ),
        'Bagus',
      );

      expect(
        () => TaskCollaborationService.validateReviewFeedback(
          '   ',
          decision: ReviewDecision.revision,
        ),
        throwsA(
          isA<TaskException>()
              .having((e) => e.code, 'code', 'invalid-review-feedback'),
        ),
      );
    });

    test('validatePicChangeReason normalizes blank and enforces max length', () {
      expect(TaskCollaborationService.validatePicChangeReason('   '), isNull);
      expect(
        TaskCollaborationService.validatePicChangeReason('  Beban penuh  '),
        'Beban penuh',
      );

      final tooLong = 'a' * (TaskCollaborationService.maxReasonLength + 1);
      expect(
        () => TaskCollaborationService.validatePicChangeReason(tooLong),
        throwsA(
          isA<TaskException>()
              .having((e) => e.code, 'code', 'invalid-pic-change-reason'),
        ),
      );
    });
  });
}
