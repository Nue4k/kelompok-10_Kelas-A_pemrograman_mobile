import 'package:creaflow/data/models/enums.dart';
import 'package:creaflow/data/repositories/task_collaboration_repository.dart';
import 'package:creaflow/data/repositories/task_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late TaskRepository taskRepository;
  late TaskCollaborationRepository collabRepository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    taskRepository = TaskRepository(firestore: firestore);
    collabRepository = TaskCollaborationRepository(firestore: firestore);
  });

  group('TaskCollaborationRepository', () {
    test('comments and attachments CRUD', () async {
      final task = await taskRepository.createTask(
        workspaceId: 'ws-1',
        picMemberId: 'u-1',
        createdBy: 'pm-1',
        title: 'Task 1',
        priority: TaskPriority.medium,
      );

      final comment = await collabRepository.addComment(
        workspaceId: 'ws-1',
        taskId: task.id,
        userId: 'u-1',
        commentText: 'Halo',
      );
      expect((await collabRepository.getComment('ws-1', task.id, comment.id))
          ?.commentText, 'Halo');

      await collabRepository.updateComment(
        workspaceId: 'ws-1',
        taskId: task.id,
        commentId: comment.id,
        commentText: 'Halo edit',
      );
      expect((await collabRepository.getComment('ws-1', task.id, comment.id))
          ?.commentText, 'Halo edit');

      await collabRepository.deleteComment(
        workspaceId: 'ws-1',
        taskId: task.id,
        commentId: comment.id,
      );
      expect(
        await collabRepository.getComment('ws-1', task.id, comment.id),
        isNull,
      );

      final att = await collabRepository.addAttachment(
        workspaceId: 'ws-1',
        taskId: task.id,
        uploadedBy: 'u-1',
        fileUrl: 'https://res.cloudinary.com/demo/image/upload/sample.jpg',
      );
      expect(
        (await collabRepository.getAttachment('ws-1', task.id, att.id))
            ?.fileUrl,
        contains('cloudinary.com'),
      );
      await collabRepository.deleteAttachment(
        workspaceId: 'ws-1',
        taskId: task.id,
        attachmentId: att.id,
      );
      expect(
        await collabRepository.getAttachment('ws-1', task.id, att.id),
        isNull,
      );
    });

    test('statusHistory, review decision, and PIC change batches', () async {
      final task = await taskRepository.createTask(
        workspaceId: 'ws-1',
        picMemberId: 'u-1',
        createdBy: 'pm-1',
        title: 'Task 2',
        priority: TaskPriority.high,
      );

      await collabRepository.updateTaskStatusWithHistory(
        workspaceId: 'ws-1',
        taskId: task.id,
        changedBy: 'u-1',
        oldStatus: TaskStatus.todo,
        newStatus: TaskStatus.inProgress,
        notes: 'Mulai kerjakan',
      );
      expect(
        (await taskRepository.getTask('ws-1', task.id))?.status,
        TaskStatus.inProgress,
      );

      final review = await collabRepository.submitReview(
        workspaceId: 'ws-1',
        taskId: task.id,
        submittedBy: 'u-1',
        oldStatus: TaskStatus.inProgress,
      );
      expect(
        (await taskRepository.getTask('ws-1', task.id))?.status,
        TaskStatus.inReview,
      );

      await collabRepository.decideReview(
        workspaceId: 'ws-1',
        taskId: task.id,
        reviewId: review.id,
        reviewedBy: 'pm-1',
        decision: ReviewDecision.revision,
        feedback: 'Perbaiki validasi',
      );
      expect(
        (await taskRepository.getTask('ws-1', task.id))?.status,
        TaskStatus.revision,
      );

      final req = await collabRepository.createPicChangeRequest(
        workspaceId: 'ws-1',
        taskId: task.id,
        requestedBy: 'u-1',
        currentPicId: 'u-1',
        proposedPicId: 'u-2',
        reason: 'Sakit',
      );
      await collabRepository.approvePicChangeRequest(
        workspaceId: 'ws-1',
        taskId: task.id,
        requestId: req.id,
        reviewedBy: 'pm-1',
        oldPicId: 'u-1',
        newPicId: 'u-2',
        reason: 'Sakit',
      );

      final updatedTask = await taskRepository.getTask('ws-1', task.id);
      expect(updatedTask?.picMemberId, 'u-2');
      final history =
          await collabRepository.watchAssignmentHistory('ws-1', task.id).first;
      expect(history, hasLength(1));
      expect(history.first.newPicId, 'u-2');
    });
  });
}
