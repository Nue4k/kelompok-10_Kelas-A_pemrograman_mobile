import 'package:firebase_auth/firebase_auth.dart';

import '../core/exceptions/task_exception.dart';
import '../data/models/enums.dart';
import '../data/models/pic_change_request_model.dart';
import '../data/models/task_assignment_history_model.dart';
import '../data/models/task_attachment_model.dart';
import '../data/models/task_comment_model.dart';
import '../data/models/task_model.dart';
import '../data/models/task_review_model.dart';
import '../data/models/task_status_history_model.dart';
import '../data/models/workspace_member_model.dart';
import '../data/repositories/activity_log_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/task_collaboration_repository.dart';
import '../data/repositories/task_repository.dart';
import '../data/repositories/workspace_member_repository.dart';

/// Business-logic layer for task collaboration: comments, attachments,
/// reviews, PIC change requests, status/assignment history, activity logs,
/// and notifications.
class TaskCollaborationService {
  TaskCollaborationService({
    TaskCollaborationRepository? collaborationRepository,
    TaskRepository? taskRepository,
    WorkspaceMemberRepository? memberRepository,
    NotificationRepository? notificationRepository,
    ActivityLogRepository? activityLogRepository,
    FirebaseAuth? auth,
  })  : _collaborationRepository =
            collaborationRepository ?? TaskCollaborationRepository(),
        _taskRepository = taskRepository ?? TaskRepository(),
        _memberRepository = memberRepository ?? WorkspaceMemberRepository(),
        _notificationRepository =
            notificationRepository ?? NotificationRepository(),
        _activityLogRepository =
            activityLogRepository ?? ActivityLogRepository(),
        _auth = auth ?? FirebaseAuth.instance;

  final TaskCollaborationRepository _collaborationRepository;
  final TaskRepository _taskRepository;
  final WorkspaceMemberRepository _memberRepository;
  final NotificationRepository _notificationRepository;
  final ActivityLogRepository _activityLogRepository;
  final FirebaseAuth _auth;

  static const int maxCommentLength = 2000;
  static const int maxFeedbackLength = 2000;
  static const int maxReasonLength = 500;
  static const int maxUrlLength = 2048;

  static String validateCommentText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const TaskException(
        code: 'invalid-comment',
        message: 'Komentar tidak boleh kosong.',
      );
    }
    if (trimmed.length > maxCommentLength) {
      throw const TaskException(
        code: 'invalid-comment',
        message: 'Komentar maksimal $maxCommentLength karakter.',
      );
    }
    return trimmed;
  }

  static String validateAttachmentUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      throw const TaskException(
        code: 'invalid-attachment-url',
        message: 'URL lampiran tidak boleh kosong.',
      );
    }
    if (trimmed.length > maxUrlLength) {
      throw const TaskException(
        code: 'invalid-attachment-url',
        message: 'URL lampiran maksimal $maxUrlLength karakter.',
      );
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      throw const TaskException(
        code: 'invalid-attachment-url',
        message: 'URL lampiran harus berupa tautan http:// atau https:// yang valid.',
      );
    }
    return trimmed;
  }

  static String? validateReviewFeedback(
    String? feedback, {
    required ReviewDecision decision,
  }) {
    final trimmed = feedback?.trim();
    final isEmpty = trimmed == null || trimmed.isEmpty;
    if (decision == ReviewDecision.revision && isEmpty) {
      throw const TaskException(
        code: 'invalid-review-feedback',
        message: 'Catatan revisi wajib diisi saat meminta revisi tugas.',
      );
    }
    if (isEmpty) return null;
    if (trimmed.length > maxFeedbackLength) {
      throw const TaskException(
        code: 'invalid-review-feedback',
        message: 'Feedback review maksimal $maxFeedbackLength karakter.',
      );
    }
    return trimmed;
  }

  static String? validatePicChangeReason(String? reason) {
    if (reason == null) return null;
    final trimmed = reason.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length > maxReasonLength) {
      throw const TaskException(
        code: 'invalid-pic-change-reason',
        message: 'Alasan ganti PIC maksimal $maxReasonLength karakter.',
      );
    }
    return trimmed;
  }

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const TaskException(
        code: 'unauthenticated',
        message: 'Silakan login terlebih dahulu.',
      );
    }
    return uid;
  }

  Future<WorkspaceMemberModel> _requireActiveMember(String workspaceId) async {
    final uid = _requireUid();
    final member = await _memberRepository.getMember(workspaceId, uid);
    if (member == null || member.status != MemberStatus.active) {
      throw const TaskException(
        code: 'permission-denied',
        message: 'Anda bukan anggota aktif workspace ini.',
      );
    }
    return member;
  }

  Future<WorkspaceMemberModel> _requireActivePm(String workspaceId) async {
    final member = await _requireActiveMember(workspaceId);
    if (member.role != MemberRole.pm) {
      throw const TaskException(
        code: 'permission-denied',
        message: 'Hanya Project Manager yang dapat melakukan tindakan ini.',
      );
    }
    return member;
  }

  Future<TaskModel> _requireActiveTask(
    String workspaceId,
    String taskId,
  ) async {
    final task = await _taskRepository.getTask(workspaceId, taskId);
    if (task == null) {
      throw const TaskException(
        code: 'task-not-found',
        message: 'Tugas tidak ditemukan.',
      );
    }
    if (task.isArchived) {
      throw const TaskException(
        code: 'task-archived',
        message: 'Tugas yang diarsipkan tidak dapat diubah.',
      );
    }
    return task;
  }

  Future<void> _notifyActivePms({
    required String workspaceId,
    required String taskId,
    required String excludeUserId,
    required NotificationType type,
    required String message,
  }) async {
    final members = await _memberRepository.getMembers(workspaceId);
    final pms = members.where(
      (m) =>
          m.status == MemberStatus.active &&
          m.role == MemberRole.pm &&
          m.userId != excludeUserId,
    );
    for (final pm in pms) {
      await _notificationRepository.createNotification(
        userId: pm.userId,
        workspaceId: workspaceId,
        taskId: taskId,
        type: type,
        message: message,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Comments
  // ---------------------------------------------------------------------------

  Future<TaskCommentModel> addComment({
    required String workspaceId,
    required String taskId,
    required String commentText,
  }) async {
    final member = await _requireActiveMember(workspaceId);
    final task = await _requireActiveTask(workspaceId, taskId);
    final validText = validateCommentText(commentText);

    try {
      final comment = await _collaborationRepository.addComment(
        workspaceId: workspaceId,
        taskId: taskId,
        userId: member.userId,
        commentText: validText,
      );
      await _activityLogRepository.createLog(
        workspaceId: workspaceId,
        userId: member.userId,
        taskId: taskId,
        activityType: ActivityType.commentAdded,
        description: 'Menambahkan komentar pada tugas "${task.title}".',
      );
      if (task.picMemberId != member.userId) {
        await _notificationRepository.createNotification(
          userId: task.picMemberId,
          workspaceId: workspaceId,
          taskId: taskId,
          type: NotificationType.commentAdded,
          message: 'Komentar baru pada tugas "${task.title}".',
        );
      }
      return comment;
    } on FirebaseException catch (e) {
      throw TaskException.fromFirebase(e);
    }
  }

  Future<void> updateComment({
    required String workspaceId,
    required String taskId,
    required String commentId,
    required String commentText,
  }) async {
    final member = await _requireActiveMember(workspaceId);
    final validText = validateCommentText(commentText);
    final existing = await _collaborationRepository.getComment(
      workspaceId,
      taskId,
      commentId,
    );
    if (existing == null) {
      throw const TaskException(
        code: 'comment-not-found',
        message: 'Komentar tidak ditemukan.',
      );
    }
    if (existing.userId != member.userId) {
      throw const TaskException(
        code: 'permission-denied',
        message: 'Anda hanya dapat mengedit komentar Anda sendiri.',
      );
    }

    try {
      await _collaborationRepository.updateComment(
        workspaceId: workspaceId,
        taskId: taskId,
        commentId: commentId,
        commentText: validText,
      );
    } on FirebaseException catch (e) {
      throw TaskException.fromFirebase(e);
    }
  }

  Future<void> deleteComment({
    required String workspaceId,
    required String taskId,
    required String commentId,
  }) async {
    final member = await _requireActiveMember(workspaceId);
    final existing = await _collaborationRepository.getComment(
      workspaceId,
      taskId,
      commentId,
    );
    if (existing == null) {
      throw const TaskException(
        code: 'comment-not-found',
        message: 'Komentar tidak ditemukan.',
      );
    }
    if (existing.userId != member.userId && member.role != MemberRole.pm) {
      throw const TaskException(
        code: 'permission-denied',
        message: 'Hanya pemilik komentar atau PM yang dapat menghapus komentar.',
      );
    }

    try {
      await _collaborationRepository.deleteComment(
        workspaceId: workspaceId,
        taskId: taskId,
        commentId: commentId,
      );
    } on FirebaseException catch (e) {
      throw TaskException.fromFirebase(e);
    }
  }

  Stream<List<TaskCommentModel>> watchComments(
    String workspaceId,
    String taskId,
  ) {
    _requireUid();
    return _collaborationRepository.watchComments(workspaceId, taskId);
  }

  // ---------------------------------------------------------------------------
  // Attachments
  // ---------------------------------------------------------------------------

  Future<TaskAttachmentModel> addAttachment({
    required String workspaceId,
    required String taskId,
    required String fileUrl,
  }) async {
    final member = await _requireActiveMember(workspaceId);
    final task = await _requireActiveTask(workspaceId, taskId);
    final validUrl = validateAttachmentUrl(fileUrl);

    try {
      final attachment = await _collaborationRepository.addAttachment(
        workspaceId: workspaceId,
        taskId: taskId,
        uploadedBy: member.userId,
        fileUrl: validUrl,
      );
      await _activityLogRepository.createLog(
        workspaceId: workspaceId,
        userId: member.userId,
        taskId: taskId,
        activityType: ActivityType.attachmentAdded,
        description: 'Menambahkan lampiran pada tugas "${task.title}".',
      );
      return attachment;
    } on FirebaseException catch (e) {
      throw TaskException.fromFirebase(e);
    }
  }

  Future<void> deleteAttachment({
    required String workspaceId,
    required String taskId,
    required String attachmentId,
  }) async {
    final member = await _requireActiveMember(workspaceId);
    final existing = await _collaborationRepository.getAttachment(
      workspaceId,
      taskId,
      attachmentId,
    );
    if (existing == null) {
      throw const TaskException(
        code: 'attachment-not-found',
        message: 'Lampiran tidak ditemukan.',
      );
    }
    if (existing.uploadedBy != member.userId && member.role != MemberRole.pm) {
      throw const TaskException(
        code: 'permission-denied',
        message: 'Hanya pengunggah atau PM yang dapat menghapus lampiran.',
      );
    }

    try {
      await _collaborationRepository.deleteAttachment(
        workspaceId: workspaceId,
        taskId: taskId,
        attachmentId: attachmentId,
      );
    } on FirebaseException catch (e) {
      throw TaskException.fromFirebase(e);
    }
  }

  Stream<List<TaskAttachmentModel>> watchAttachments(
    String workspaceId,
    String taskId,
  ) {
    _requireUid();
    return _collaborationRepository.watchAttachments(workspaceId, taskId);
  }

  // ---------------------------------------------------------------------------
  // Status History & Reviews
  // ---------------------------------------------------------------------------

  Stream<List<TaskStatusHistoryModel>> watchStatusHistory(
    String workspaceId,
    String taskId,
  ) {
    _requireUid();
    return _collaborationRepository.watchStatusHistory(workspaceId, taskId);
  }

  Future<TaskReviewModel> submitForReview({
    required String workspaceId,
    required String taskId,
    String? notes,
  }) async {
    final member = await _requireActiveMember(workspaceId);
    final task = await _requireActiveTask(workspaceId, taskId);

    final isPm = member.role == MemberRole.pm;
    final isPic = task.picMemberId == member.userId;
    if (!isPm && !isPic) {
      throw const TaskException(
        code: 'permission-denied',
        message: 'Hanya PIC atau PM yang dapat mengajukan review tugas.',
      );
    }
    if (task.status != TaskStatus.inProgress) {
      throw const TaskException(
        code: 'invalid-status-transition',
        message:
            'Tugas hanya dapat diajukan untuk review saat berstatus in_progress.',
      );
    }

    final trimmedNotes = notes?.trim();
    try {
      final review = await _collaborationRepository.submitReview(
        workspaceId: workspaceId,
        taskId: taskId,
        submittedBy: member.userId,
        oldStatus: task.status,
        notes: (trimmedNotes == null || trimmedNotes.isEmpty)
            ? null
            : trimmedNotes,
      );
      await _activityLogRepository.createLog(
        workspaceId: workspaceId,
        userId: member.userId,
        taskId: taskId,
        activityType: ActivityType.taskStatusChanged,
        description: 'Mengajukan review untuk tugas "${task.title}".',
      );
      await _notifyActivePms(
        workspaceId: workspaceId,
        taskId: taskId,
        excludeUserId: member.userId,
        type: NotificationType.reviewRequested,
        message: 'Tugas "${task.title}" menunggu review Anda.',
      );
      return review;
    } on FirebaseException catch (e) {
      throw TaskException.fromFirebase(e);
    }
  }

  Future<void> reviewTask({
    required String workspaceId,
    required String taskId,
    required String reviewId,
    required ReviewDecision decision,
    String? feedback,
  }) async {
    final pm = await _requireActivePm(workspaceId);
    final task = await _requireActiveTask(workspaceId, taskId);
    if (task.status != TaskStatus.inReview) {
      throw const TaskException(
        code: 'invalid-status-transition',
        message: 'Tugas hanya dapat direview saat berstatus in_review.',
      );
    }

    final review = await _collaborationRepository.getReview(
      workspaceId,
      taskId,
      reviewId,
    );
    if (review == null) {
      throw const TaskException(
        code: 'review-not-found',
        message: 'Data review tidak ditemukan.',
      );
    }
    if (review.decision != null) {
      throw const TaskException(
        code: 'review-already-decided',
        message: 'Review ini sudah diputuskan sebelumnya.',
      );
    }

    final validFeedback = validateReviewFeedback(feedback, decision: decision);

    try {
      await _collaborationRepository.decideReview(
        workspaceId: workspaceId,
        taskId: taskId,
        reviewId: reviewId,
        reviewedBy: pm.userId,
        decision: decision,
        feedback: validFeedback,
      );
      final isApproved = decision == ReviewDecision.approved;
      await _activityLogRepository.createLog(
        workspaceId: workspaceId,
        userId: pm.userId,
        taskId: taskId,
        activityType: ActivityType.taskReviewed,
        description: isApproved
            ? 'Menyetujui tugas "${task.title}".'
            : 'Meminta revisi pada tugas "${task.title}".',
      );
      if (task.picMemberId != pm.userId) {
        await _notificationRepository.createNotification(
          userId: task.picMemberId,
          workspaceId: workspaceId,
          taskId: taskId,
          type: isApproved
              ? NotificationType.taskApproved
              : NotificationType.revisionRequested,
          message: isApproved
              ? 'Tugas "${task.title}" telah disetujui.'
              : 'Tugas "${task.title}" perlu revisi.',
        );
      }
    } on FirebaseException catch (e) {
      throw TaskException.fromFirebase(e);
    }
  }

  Stream<List<TaskReviewModel>> watchReviews(
    String workspaceId,
    String taskId,
  ) {
    _requireUid();
    return _collaborationRepository.watchReviews(workspaceId, taskId);
  }

  // ---------------------------------------------------------------------------
  // PIC Change Requests & Assignment History
  // ---------------------------------------------------------------------------

  Future<PicChangeRequestModel> requestPicChange({
    required String workspaceId,
    required String taskId,
    required String proposedPicId,
    String? reason,
  }) async {
    final member = await _requireActiveMember(workspaceId);
    final task = await _requireActiveTask(workspaceId, taskId);
    final trimmedProposed = proposedPicId.trim();
    if (trimmedProposed.isEmpty || trimmedProposed == task.picMemberId) {
      throw const TaskException(
        code: 'invalid-pic',
        message: 'Calon PIC baru harus berbeda dari PIC saat ini.',
      );
    }

    final targetMember = await _memberRepository.getMember(
      workspaceId,
      trimmedProposed,
    );
    if (targetMember == null || targetMember.status != MemberStatus.active) {
      throw const TaskException(
        code: 'invalid-pic',
        message: 'Calon PIC harus merupakan anggota aktif workspace ini.',
      );
    }

    final validReason = validatePicChangeReason(reason);

    try {
      final request = await _collaborationRepository.createPicChangeRequest(
        workspaceId: workspaceId,
        taskId: taskId,
        requestedBy: member.userId,
        currentPicId: task.picMemberId,
        proposedPicId: trimmedProposed,
        reason: validReason,
      );
      await _notifyActivePms(
        workspaceId: workspaceId,
        taskId: taskId,
        excludeUserId: member.userId,
        type: NotificationType.picChangeRequested,
        message: 'Ada permintaan ganti PIC untuk tugas "${task.title}".',
      );
      return request;
    } on FirebaseException catch (e) {
      throw TaskException.fromFirebase(e);
    }
  }

  Future<void> approvePicChangeRequest({
    required String workspaceId,
    required String taskId,
    required String requestId,
  }) async {
    final pm = await _requireActivePm(workspaceId);
    final task = await _requireActiveTask(workspaceId, taskId);
    final request = await _collaborationRepository.getPicChangeRequest(
      workspaceId,
      taskId,
      requestId,
    );
    if (request == null) {
      throw const TaskException(
        code: 'pic-request-not-found',
        message: 'Permintaan ganti PIC tidak ditemukan.',
      );
    }
    if (request.status != RequestStatus.pending) {
      throw const TaskException(
        code: 'pic-request-already-processed',
        message: 'Permintaan ganti PIC ini sudah diproses.',
      );
    }

    final targetMember = await _memberRepository.getMember(
      workspaceId,
      request.proposedPicId,
    );
    if (targetMember == null || targetMember.status != MemberStatus.active) {
      throw const TaskException(
        code: 'invalid-pic',
        message: 'Calon PIC bukan lagi anggota aktif workspace ini.',
      );
    }

    try {
      await _collaborationRepository.approvePicChangeRequest(
        workspaceId: workspaceId,
        taskId: taskId,
        requestId: requestId,
        reviewedBy: pm.userId,
        oldPicId: task.picMemberId,
        newPicId: request.proposedPicId,
        reason: request.reason,
      );
      await _activityLogRepository.createLog(
        workspaceId: workspaceId,
        userId: pm.userId,
        taskId: taskId,
        activityType: ActivityType.picChanged,
        description: 'Mengganti PIC pada tugas "${task.title}".',
      );
      if (request.proposedPicId != pm.userId) {
        await _notificationRepository.createNotification(
          userId: request.proposedPicId,
          workspaceId: workspaceId,
          taskId: taskId,
          type: NotificationType.taskAssigned,
          message: 'Anda ditunjuk sebagai PIC baru untuk tugas "${task.title}".',
        );
      }
    } on FirebaseException catch (e) {
      throw TaskException.fromFirebase(e);
    }
  }

  Future<void> rejectPicChangeRequest({
    required String workspaceId,
    required String taskId,
    required String requestId,
  }) async {
    final pm = await _requireActivePm(workspaceId);
    final request = await _collaborationRepository.getPicChangeRequest(
      workspaceId,
      taskId,
      requestId,
    );
    if (request == null) {
      throw const TaskException(
        code: 'pic-request-not-found',
        message: 'Permintaan ganti PIC tidak ditemukan.',
      );
    }
    if (request.status != RequestStatus.pending) {
      throw const TaskException(
        code: 'pic-request-already-processed',
        message: 'Permintaan ganti PIC ini sudah diproses.',
      );
    }

    try {
      await _collaborationRepository.rejectPicChangeRequest(
        workspaceId: workspaceId,
        taskId: taskId,
        requestId: requestId,
        reviewedBy: pm.userId,
      );
    } on FirebaseException catch (e) {
      throw TaskException.fromFirebase(e);
    }
  }

  Stream<List<PicChangeRequestModel>> watchPicChangeRequests(
    String workspaceId,
    String taskId,
  ) {
    _requireUid();
    return _collaborationRepository.watchPicChangeRequests(workspaceId, taskId);
  }

  Stream<List<TaskAssignmentHistoryModel>> watchAssignmentHistory(
    String workspaceId,
    String taskId,
  ) {
    _requireUid();
    return _collaborationRepository.watchAssignmentHistory(workspaceId, taskId);
  }
}
