import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:creaflow/data/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ts1 = DateTime(2026, 11, 20, 9, 0);
  final ts2 = DateTime(2026, 11, 21, 14, 30);

  test('WorkspaceModel round-trip', () {
    final model = WorkspaceModel(
      id: 'ws-1',
      name: 'CreaFlow Team',
      description: 'Mobile project',
      inviteCode: 'CF2026',
      status: WorkspaceStatus.active,
      createdBy: 'u-1',
      createdAt: ts1,
      updatedAt: ts2,
    );

    final map = model.toMap();
    expect(map['workspaceName'], 'CreaFlow Team');
    expect(map['createdAt'], isA<Timestamp>());
    expect(map.containsKey('id'), isFalse);

    final restored = WorkspaceModel.fromMap('ws-1', map);
    expect(restored.id, 'ws-1');
    expect(restored.name, 'CreaFlow Team');
    expect(restored.description, 'Mobile project');
    expect(restored.inviteCode, 'CF2026');
    expect(restored.status, WorkspaceStatus.active);
    expect(restored.createdBy, 'u-1');
    expect(restored.createdAt, ts1);
    expect(restored.updatedAt, ts2);
  });

  test('WorkspaceMemberModel round-trip, isPm, and userId fallback', () {
    final pm = WorkspaceMemberModel(
      id: 'u-1',
      workspaceId: 'ws-1',
      userId: 'u-1',
      role: MemberRole.pm,
      status: MemberStatus.active,
      joinedAt: ts1,
    );
    expect(pm.isPm, isTrue);

    final restored = WorkspaceMemberModel.fromMap('u-1', pm.toMap());
    expect(restored.isPm, isTrue);
    expect(restored.joinedAt, ts1);

    final fallback = WorkspaceMemberModel.fromMap('u-2', {
      'workspaceId': 'ws-1',
      'role': 'member',
      'status': 'active',
    });
    expect(fallback.userId, 'u-2');
    expect(fallback.isPm, isFalse);
  });

  test('JoinRequestModel round-trip and userId fallback', () {
    final model = JoinRequestModel(
      id: 'u-3',
      workspaceId: 'ws-1',
      userId: 'u-3',
      status: RequestStatus.approved,
      requestedAt: ts1,
      reviewedAt: ts2,
      reviewedBy: 'u-1',
    );

    final restored = JoinRequestModel.fromMap('u-3', model.toMap());
    expect(restored.status, RequestStatus.approved);
    expect(restored.requestedAt, ts1);
    expect(restored.reviewedAt, ts2);
    expect(restored.reviewedBy, 'u-1');

    final fallback = JoinRequestModel.fromMap('u-4', {
      'workspaceId': 'ws-1',
      'status': 'pending',
    });
    expect(fallback.userId, 'u-4');
  });

  test('TaskAttachmentModel round-trip', () {
    final model = TaskAttachmentModel(
      id: 'att-1',
      taskId: 't-1',
      uploadedBy: 'u-2',
      fileUrl: 'https://res.cloudinary.com/demo/image/upload/v1/doc.pdf',
      uploadedAt: ts1,
    );

    final map = model.toMap();
    expect(map['uploadedAt'], isA<Timestamp>());

    final restored = TaskAttachmentModel.fromMap('att-1', map);
    expect(restored.id, 'att-1');
    expect(restored.taskId, 't-1');
    expect(restored.uploadedBy, 'u-2');
    expect(restored.fileUrl, model.fileUrl);
    expect(restored.uploadedAt, ts1);
  });

  test('TaskCommentModel round-trip', () {
    final model = TaskCommentModel(
      id: 'c-1',
      taskId: 't-1',
      userId: 'u-2',
      commentText: 'Progress updated',
      createdAt: ts1,
      updatedAt: ts2,
    );

    final restored = TaskCommentModel.fromMap('c-1', model.toMap());
    expect(restored.commentText, 'Progress updated');
    expect(restored.createdAt, ts1);
    expect(restored.updatedAt, ts2);
  });

  test('TaskStatusHistoryModel round-trip with null and non-null oldStatus', () {
    final initial = TaskStatusHistoryModel(
      id: 'h-1',
      taskId: 't-1',
      changedBy: 'u-1',
      oldStatus: null,
      newStatus: TaskStatus.todo,
      notes: 'Created',
      changedAt: ts1,
    ); 
    final restoredInitial =
        TaskStatusHistoryModel.fromMap('h-1', initial.toMap());
    expect(restoredInitial.oldStatus, isNull);
    expect(restoredInitial.newStatus, TaskStatus.todo);
    expect(restoredInitial.changedAt, ts1);

    final moved = TaskStatusHistoryModel(
      id: 'h-2',
      taskId: 't-1',
      changedBy: 'u-2',
      oldStatus: TaskStatus.todo,
      newStatus: TaskStatus.inProgress,
      changedAt: ts2,
    );
    final restoredMoved = TaskStatusHistoryModel.fromMap('h-2', moved.toMap());
    expect(restoredMoved.oldStatus, TaskStatus.todo);
    expect(restoredMoved.newStatus, TaskStatus.inProgress);
  });

  test('TaskReviewModel round-trip with pending and approved decision', () {
    final pending = TaskReviewModel(
      id: 'r-1',
      taskId: 't-1',
      submittedBy: 'u-2',
      submittedAt: ts1,
    );
    final restoredPending = TaskReviewModel.fromMap('r-1', pending.toMap());
    expect(restoredPending.decision, isNull);
    expect(restoredPending.reviewedBy, isNull);

    final approved = TaskReviewModel(
      id: 'r-2',
      taskId: 't-1',
      submittedBy: 'u-2',
      reviewedBy: 'u-1',
      decision: ReviewDecision.approved,
      feedback: 'LGTM',
      submittedAt: ts1,
      reviewedAt: ts2,
    );
    final restoredApproved = TaskReviewModel.fromMap('r-2', approved.toMap());
    expect(restoredApproved.decision, ReviewDecision.approved);
    expect(restoredApproved.reviewedBy, 'u-1');
    expect(restoredApproved.feedback, 'LGTM');
    expect(restoredApproved.reviewedAt, ts2);
  });

  test('PicChangeRequestModel round-trip', () {
    final model = PicChangeRequestModel(
      id: 'pcr-1',
      taskId: 't-1',
      requestedBy: 'u-2',
      currentPicId: 'u-2',
      proposedPicId: 'u-3',
      status: RequestStatus.pending,
      reason: 'Need backend help',
      requestedAt: ts1,
      reviewedBy: 'u-1',
      reviewedAt: ts2,
    );

    final restored = PicChangeRequestModel.fromMap('pcr-1', model.toMap());
    expect(restored.currentPicId, 'u-2');
    expect(restored.proposedPicId, 'u-3');
    expect(restored.status, RequestStatus.pending);
    expect(restored.reason, 'Need backend help');
    expect(restored.reviewedBy, 'u-1');
    expect(restored.reviewedAt, ts2);
  });

  test('TaskAssignmentHistoryModel round-trip', () {
    final model = TaskAssignmentHistoryModel(
      id: 'ah-1',
      taskId: 't-1',
      oldPicId: null,
      newPicId: 'u-2',
      changedBy: 'u-1',
      reason: 'Initial assignment',
      changedAt: ts1,
    );

    final restored = TaskAssignmentHistoryModel.fromMap('ah-1', model.toMap());
    expect(restored.oldPicId, isNull);
    expect(restored.newPicId, 'u-2');
    expect(restored.changedBy, 'u-1');
    expect(restored.reason, 'Initial assignment');
    expect(restored.changedAt, ts1);
  });

  test('ActivityLogModel round-trip', () {
    final model = ActivityLogModel(
      id: 'log-1',
      workspaceId: 'ws-1',
      userId: 'u-1',
      taskId: null,
      activityType: ActivityType.workspaceCreated,
      description: 'Created workspace',
      createdAt: ts1,
    );

    final restored = ActivityLogModel.fromMap('log-1', model.toMap());
    expect(restored.workspaceId, 'ws-1');
    expect(restored.taskId, isNull);
    expect(restored.activityType, ActivityType.workspaceCreated);
    expect(restored.description, 'Created workspace');
    expect(restored.createdAt, ts1);
  });
}
