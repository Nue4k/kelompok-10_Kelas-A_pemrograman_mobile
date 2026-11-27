import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_collections.dart';
import '../models/enums.dart';
import '../models/pic_change_request_model.dart';
import '../models/task_assignment_history_model.dart';
import '../models/task_attachment_model.dart';
import '../models/task_comment_model.dart';
import '../models/task_review_model.dart';
import '../models/task_status_history_model.dart';

/// Repository for task collaboration subcollections under
/// `workspaces/{workspaceId}/tasks/{taskId}`.
class TaskCollaborationRepository {
  TaskCollaborationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _taskRef(
    String workspaceId,
    String taskId,
  ) =>
      _firestore
          .collection(FirestoreCollections.workspaces)
          .doc(workspaceId)
          .collection(FirestoreCollections.tasks)
          .doc(taskId);

  CollectionReference<Map<String, dynamic>> _commentsRef(
    String workspaceId,
    String taskId,
  ) =>
      _taskRef(workspaceId, taskId).collection(FirestoreCollections.comments);

  CollectionReference<Map<String, dynamic>> _attachmentsRef(
    String workspaceId,
    String taskId,
  ) =>
      _taskRef(workspaceId, taskId)
          .collection(FirestoreCollections.attachments);

  CollectionReference<Map<String, dynamic>> _statusHistoryRef(
    String workspaceId,
    String taskId,
  ) =>
      _taskRef(workspaceId, taskId)
          .collection(FirestoreCollections.statusHistory);

  CollectionReference<Map<String, dynamic>> _reviewsRef(
    String workspaceId,
    String taskId,
  ) =>
      _taskRef(workspaceId, taskId).collection(FirestoreCollections.reviews);

  CollectionReference<Map<String, dynamic>> _picRequestsRef(
    String workspaceId,
    String taskId,
  ) =>
      _taskRef(workspaceId, taskId)
          .collection(FirestoreCollections.picChangeRequests);

  CollectionReference<Map<String, dynamic>> _assignmentHistoryRef(
    String workspaceId,
    String taskId,
  ) =>
      _taskRef(workspaceId, taskId)
          .collection(FirestoreCollections.assignmentHistory);

  // ---------------------------------------------------------------------------
  // Comments
  // ---------------------------------------------------------------------------

  Future<TaskCommentModel> addComment({
    required String workspaceId,
    required String taskId,
    required String userId,
    required String commentText,
  }) async {
    final docRef = _commentsRef(workspaceId, taskId).doc();
    await docRef.set({
      'taskId': taskId,
      'userId': userId,
      'commentText': commentText,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return TaskCommentModel(
      id: docRef.id,
      taskId: taskId,
      userId: userId,
      commentText: commentText,
    );
  }

  Future<TaskCommentModel?> getComment(
    String workspaceId,
    String taskId,
    String commentId,
  ) async {
    final doc = await _commentsRef(workspaceId, taskId).doc(commentId).get();
    if (!doc.exists || doc.data() == null) return null;
    return TaskCommentModel.fromFirestore(doc);
  }

  Future<void> updateComment({
    required String workspaceId,
    required String taskId,
    required String commentId,
    required String commentText,
  }) async {
    await _commentsRef(workspaceId, taskId).doc(commentId).update({
      'commentText': commentText,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteComment({
    required String workspaceId,
    required String taskId,
    required String commentId,
  }) async {
    await _commentsRef(workspaceId, taskId).doc(commentId).delete();
  }

  Stream<List<TaskCommentModel>> watchComments(
    String workspaceId,
    String taskId,
  ) {
    return _commentsRef(workspaceId, taskId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(TaskCommentModel.fromFirestore).toList());
  }

  // ---------------------------------------------------------------------------
  // Attachments
  // ---------------------------------------------------------------------------

  Future<TaskAttachmentModel> addAttachment({
    required String workspaceId,
    required String taskId,
    required String uploadedBy,
    required String fileUrl,
  }) async {
    final docRef = _attachmentsRef(workspaceId, taskId).doc();
    await docRef.set({
      'taskId': taskId,
      'uploadedBy': uploadedBy,
      'fileUrl': fileUrl,
      'uploadedAt': FieldValue.serverTimestamp(),
    });

    return TaskAttachmentModel(
      id: docRef.id,
      taskId: taskId,
      uploadedBy: uploadedBy,
      fileUrl: fileUrl,
    );
  }

  Future<TaskAttachmentModel?> getAttachment(
    String workspaceId,
    String taskId,
    String attachmentId,
  ) async {
    final doc =
        await _attachmentsRef(workspaceId, taskId).doc(attachmentId).get();
    if (!doc.exists || doc.data() == null) return null;
    return TaskAttachmentModel.fromFirestore(doc);
  }

  Future<void> deleteAttachment({
    required String workspaceId,
    required String taskId,
    required String attachmentId,
  }) async {
    await _attachmentsRef(workspaceId, taskId).doc(attachmentId).delete();
  }

  Stream<List<TaskAttachmentModel>> watchAttachments(
    String workspaceId,
    String taskId,
  ) {
    return _attachmentsRef(workspaceId, taskId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map(TaskAttachmentModel.fromFirestore).toList(),
        );
  }

  // ---------------------------------------------------------------------------
  // Status History + Atomic Task Status Update
  // ---------------------------------------------------------------------------

  Future<TaskStatusHistoryModel> updateTaskStatusWithHistory({
    required String workspaceId,
    required String taskId,
    required String changedBy,
    required TaskStatus oldStatus,
    required TaskStatus newStatus,
    String? notes,
  }) async {
    final batch = _firestore.batch();
    final taskRef = _taskRef(workspaceId, taskId);
    final historyRef = _statusHistoryRef(workspaceId, taskId).doc();

    batch.update(taskRef, {
      'status': newStatus.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(historyRef, {
      'taskId': taskId,
      'changedBy': changedBy,
      'oldStatus': oldStatus.value,
      'newStatus': newStatus.value,
      'notes': notes,
      'changedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    return TaskStatusHistoryModel(
      id: historyRef.id,
      taskId: taskId,
      changedBy: changedBy,
      oldStatus: oldStatus,
      newStatus: newStatus,
      notes: notes,
    );
  }

  Stream<List<TaskStatusHistoryModel>> watchStatusHistory(
    String workspaceId,
    String taskId,
  ) {
    return _statusHistoryRef(workspaceId, taskId)
        .orderBy('changedAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map(TaskStatusHistoryModel.fromFirestore).toList(),
        );
  }

  // ---------------------------------------------------------------------------
  // Reviews
  // ---------------------------------------------------------------------------

  Future<TaskReviewModel> submitReview({
    required String workspaceId,
    required String taskId,
    required String submittedBy,
    required TaskStatus oldStatus,
    String? notes,
  }) async {
    final batch = _firestore.batch();
    final taskRef = _taskRef(workspaceId, taskId);
    final reviewRef = _reviewsRef(workspaceId, taskId).doc();
    final historyRef = _statusHistoryRef(workspaceId, taskId).doc();

    batch.update(taskRef, {
      'status': TaskStatus.inReview.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(reviewRef, {
      'taskId': taskId,
      'submittedBy': submittedBy,
      'reviewedBy': null,
      'decision': null,
      'feedback': null,
      'submittedAt': FieldValue.serverTimestamp(),
      'reviewedAt': null,
    });

    batch.set(historyRef, {
      'taskId': taskId,
      'changedBy': submittedBy,
      'oldStatus': oldStatus.value,
      'newStatus': TaskStatus.inReview.value,
      'notes': notes,
      'changedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    return TaskReviewModel(
      id: reviewRef.id,
      taskId: taskId,
      submittedBy: submittedBy,
    );
  }

  Future<void> decideReview({
    required String workspaceId,
    required String taskId,
    required String reviewId,
    required String reviewedBy,
    required ReviewDecision decision,
    String? feedback,
  }) async {
    final nextStatus =
        decision == ReviewDecision.approved ? TaskStatus.done : TaskStatus.revision;

    final batch = _firestore.batch();
    final reviewRef = _reviewsRef(workspaceId, taskId).doc(reviewId);
    final taskRef = _taskRef(workspaceId, taskId);
    final historyRef = _statusHistoryRef(workspaceId, taskId).doc();

    batch.update(reviewRef, {
      'reviewedBy': reviewedBy,
      'decision': decision.value,
      'feedback': feedback,
      'reviewedAt': FieldValue.serverTimestamp(),
    });

    batch.update(taskRef, {
      'status': nextStatus.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(historyRef, {
      'taskId': taskId,
      'changedBy': reviewedBy,
      'oldStatus': TaskStatus.inReview.value,
      'newStatus': nextStatus.value,
      'notes': feedback,
      'changedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<TaskReviewModel?> getReview(
    String workspaceId,
    String taskId,
    String reviewId,
  ) async {
    final doc = await _reviewsRef(workspaceId, taskId).doc(reviewId).get();
    if (!doc.exists || doc.data() == null) return null;
    return TaskReviewModel.fromFirestore(doc);
  }

  Stream<List<TaskReviewModel>> watchReviews(
    String workspaceId,
    String taskId,
  ) {
    return _reviewsRef(workspaceId, taskId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(TaskReviewModel.fromFirestore).toList());
  }

  // ---------------------------------------------------------------------------
  // PIC Change Requests & Assignment History
  // ---------------------------------------------------------------------------

  Future<PicChangeRequestModel> createPicChangeRequest({
    required String workspaceId,
    required String taskId,
    required String requestedBy,
    required String currentPicId,
    required String proposedPicId,
    String? reason,
  }) async {
    final docRef = _picRequestsRef(workspaceId, taskId).doc();
    await docRef.set({
      'taskId': taskId,
      'requestedBy': requestedBy,
      'currentPicId': currentPicId,
      'proposedPicId': proposedPicId,
      'status': RequestStatus.pending.value,
      'reason': reason,
      'requestedAt': FieldValue.serverTimestamp(),
      'reviewedBy': null,
      'reviewedAt': null,
    });

    return PicChangeRequestModel(
      id: docRef.id,
      taskId: taskId,
      requestedBy: requestedBy,
      currentPicId: currentPicId,
      proposedPicId: proposedPicId,
      status: RequestStatus.pending,
      reason: reason,
    );
  }

  Future<PicChangeRequestModel?> getPicChangeRequest(
    String workspaceId,
    String taskId,
    String requestId,
  ) async {
    final doc = await _picRequestsRef(workspaceId, taskId).doc(requestId).get();
    if (!doc.exists || doc.data() == null) return null;
    return PicChangeRequestModel.fromFirestore(doc);
  }

  Stream<List<PicChangeRequestModel>> watchPicChangeRequests(
    String workspaceId,
    String taskId,
  ) {
    return _picRequestsRef(workspaceId, taskId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map(PicChangeRequestModel.fromFirestore).toList(),
        );
  }

  Future<void> approvePicChangeRequest({
    required String workspaceId,
    required String taskId,
    required String requestId,
    required String reviewedBy,
    required String oldPicId,
    required String newPicId,
    String? reason,
  }) async {
    final batch = _firestore.batch();
    final reqRef = _picRequestsRef(workspaceId, taskId).doc(requestId);
    final taskRef = _taskRef(workspaceId, taskId);
    final historyRef = _assignmentHistoryRef(workspaceId, taskId).doc();

    batch.update(reqRef, {
      'status': RequestStatus.approved.value,
      'reviewedBy': reviewedBy,
      'reviewedAt': FieldValue.serverTimestamp(),
    });

    batch.update(taskRef, {
      'picMemberId': newPicId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(historyRef, {
      'taskId': taskId,
      'oldPicId': oldPicId,
      'newPicId': newPicId,
      'changedBy': reviewedBy,
      'reason': reason,
      'changedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> rejectPicChangeRequest({
    required String workspaceId,
    required String taskId,
    required String requestId,
    required String reviewedBy,
  }) async {
    await _picRequestsRef(workspaceId, taskId).doc(requestId).update({
      'status': RequestStatus.rejected.value,
      'reviewedBy': reviewedBy,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<TaskAssignmentHistoryModel>> watchAssignmentHistory(
    String workspaceId,
    String taskId,
  ) {
    return _assignmentHistoryRef(workspaceId, taskId)
        .orderBy('changedAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map(TaskAssignmentHistoryModel.fromFirestore).toList(),
        );
  }
}
