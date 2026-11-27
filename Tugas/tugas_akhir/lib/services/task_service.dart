import 'package:firebase_auth/firebase_auth.dart';

import '../core/exceptions/task_exception.dart';
import '../core/utils/task_status_transition.dart';
import '../data/models/enums.dart';
import '../data/models/task_model.dart';
import '../data/models/workspace_member_model.dart';
import '../data/repositories/task_repository.dart';
import '../data/repositories/workspace_member_repository.dart';

/// Business-logic layer for core task CRUD, PIC assignment, archive, and
/// role-based status transitions.
class TaskService {
  TaskService({
    TaskRepository? taskRepository,
    WorkspaceMemberRepository? memberRepository,
    FirebaseAuth? auth,
  })  : _taskRepository = taskRepository ?? TaskRepository(),
        _memberRepository = memberRepository ?? WorkspaceMemberRepository(),
        _auth = auth ?? FirebaseAuth.instance;

  final TaskRepository _taskRepository;
  final WorkspaceMemberRepository _memberRepository;
  final FirebaseAuth _auth;

  static const int maxTitleLength = 150;
  static const int maxDescriptionLength = 2000;

  static String validateTitle(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw const TaskException(
        code: 'invalid-title',
        message: 'Judul tugas tidak boleh kosong.',
      );
    }
    if (trimmed.length > maxTitleLength) {
      throw const TaskException(
        code: 'invalid-title',
        message: 'Judul tugas maksimal $maxTitleLength karakter.',
      );
    }
    return trimmed;
  }

  static String? validateDescription(String? description) {
    if (description == null) return null;
    final trimmed = description.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length > maxDescriptionLength) {
      throw const TaskException(
        code: 'invalid-description',
        message: 'Deskripsi tugas maksimal $maxDescriptionLength karakter.',
      );
    }
    return trimmed;
  }

  static void validateDateRange({
    DateTime? startDate,
    DateTime? deadline,
  }) {
    if (startDate != null && deadline != null && deadline.isBefore(startDate)) {
      throw const TaskException(
        code: 'invalid-date-range',
        message: 'Deadline tidak boleh lebih awal dari tanggal mulai.',
      );
    }
  }

  static void validateStatusTransition({
    required TaskStatus from,
    required TaskStatus to,
    required bool isPm,
    required bool isPic,
  }) {
    if (TaskStatusTransition.canTransition(
      from: from,
      to: to,
      isPm: isPm,
      isPic: isPic,
    )) {
      return;
    }

    if (from == TaskStatus.inReview &&
        (to == TaskStatus.done || to == TaskStatus.revision) &&
        !isPm) {
      throw const TaskException(
        code: 'invalid-status-transition',
        message:
            'Hanya Project Manager yang dapat menyetujui atau meminta revisi tugas.',
      );
    }

    throw TaskException(
      code: 'invalid-status-transition',
      message:
          'Perubahan status dari "${from.value}" ke "${to.value}" tidak diizinkan.',
    );
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

  Future<void> _requireActiveTargetMember(
    String workspaceId,
    String userId,
  ) async {
    final trimmed = userId.trim();
    if (trimmed.isEmpty) {
      throw const TaskException(
        code: 'invalid-pic',
        message: 'PIC tugas wajib dipilih.',
      );
    }
    final target = await _memberRepository.getMember(workspaceId, trimmed);
    if (target == null || target.status != MemberStatus.active) {
      throw const TaskException(
        code: 'invalid-pic',
        message: 'PIC harus merupakan anggota aktif workspace ini.',
      );
    }
  }

  Future<TaskModel> createTask({
    required String workspaceId,
    required String picMemberId,
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? deadline,
    TaskPriority priority = TaskPriority.medium,
  }) async {
    final pm = await _requireActivePm(workspaceId);
    final validTitle = validateTitle(title);
    final validDescription = validateDescription(description);
    validateDateRange(startDate: startDate, deadline: deadline);
    await _requireActiveTargetMember(workspaceId, picMemberId);

    try {
      return await _taskRepository.createTask(
        workspaceId: workspaceId,
        picMemberId: picMemberId.trim(),
        createdBy: pm.userId,
        title: validTitle,
        description: validDescription,
        startDate: startDate,
        deadline: deadline,
        priority: priority,
      );
    } on FirebaseException catch (e) {
      throw TaskException.fromFirebase(e);
    }
  }

  Future<TaskModel?> getTask(String workspaceId, String taskId) async {
    _requireUid();
    try {
      return await _taskRepository.getTask(workspaceId, taskId);
    } on FirebaseException catch (e) {
      throw TaskException.fromFirebase(e);
    }
  }

  Stream<TaskModel?> watchTask(String workspaceId, String taskId) {
    _requireUid();
    return _taskRepository.watchTask(workspaceId, taskId);
  }

  Future<List<TaskModel>> getTasks(
    String workspaceId, {
    bool includeArchived = false,
  }) async {
    _requireUid();
    try {
      return await _taskRepository.getTasks(
        workspaceId,
        includeArchived: includeArchived,
      );
    } on FirebaseException catch (e) {
      throw TaskException.fromFirebase(e);
    }
  }

  Stream<List<TaskModel>> watchTasks(
    String workspaceId, {
    bool includeArchived = false,
  }) {
    _requireUid();
    return _taskRepository.watchTasks(
      workspaceId,
      includeArchived: includeArchived,
    );
  }

  Future<void> updateTask({
    required String workspaceId,
    required String taskId,
    String? title,
    String? description,
    bool clearDescription = false,
    String? picMemberId,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? deadline,
    bool clearDeadline = false,
    TaskPriority? priority,
  }) async {
    await _requireActivePm(workspaceId);

    final existing = await _taskRepository.getTask(workspaceId, taskId);
    if (existing == null) {
      throw const TaskException(
        code: 'task-not-found',
        message: 'Tugas tidak ditemukan.',
      );
    }
    if (existing.isArchived) {
      throw const TaskException(
        code: 'task-archived',
        message: 'Tugas yang diarsipkan tidak dapat diubah.',
      );
    }

    final validTitle = title != null ? validateTitle(title) : null;
    final validDescription =
        clearDescription ? null : validateDescription(description);

    final effectiveStart =
        clearStartDate ? null : (startDate ?? existing.startDate);
    final effectiveDeadline =
        clearDeadline ? null : (deadline ?? existing.deadline);
    validateDateRange(startDate: effectiveStart, deadline: effectiveDeadline);

    String? validPic;
    if (picMemberId != null) {
      await _requireActiveTargetMember(workspaceId, picMemberId);
      validPic = picMemberId.trim();
    }

    try {
      await _taskRepository.updateTask(
        workspaceId: workspaceId,
        taskId: taskId,
        title: validTitle,
        description: validDescription,
        clearDescription: clearDescription,
        picMemberId: validPic,
        startDate: startDate,
        clearStartDate: clearStartDate,
        deadline: deadline,
        clearDeadline: clearDeadline,
        priority: priority,
      );
    } on FirebaseException catch (e) {
      throw TaskException.fromFirebase(e);
    }
  }

  Future<void> updateTaskStatus({
    required String workspaceId,
    required String taskId,
    required TaskStatus newStatus,
  }) async {
    final member = await _requireActiveMember(workspaceId);

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
        message: 'Status tugas yang diarsipkan tidak dapat diubah.',
      );
    }

    final isPm = member.role == MemberRole.pm;
    final isPic = task.picMemberId == member.userId;
    if (!isPm && !isPic) {
      throw const TaskException(
        code: 'permission-denied',
        message:
            'Hanya PM atau PIC tugas yang dapat mengubah status tugas ini.',
      );
    }

    validateStatusTransition(
      from: task.status,
      to: newStatus,
      isPm: isPm,
      isPic: isPic,
    );

    try {
      await _taskRepository.updateTaskStatus(
        workspaceId: workspaceId,
        taskId: taskId,
        newStatus: newStatus,
      );
    } on FirebaseException catch (e) {
      throw TaskException.fromFirebase(e);
    }
  }

  Future<void> archiveTask({
    required String workspaceId,
    required String taskId,
  }) async {
    await _requireActivePm(workspaceId);
    final task = await _taskRepository.getTask(workspaceId, taskId);
    if (task == null) {
      throw const TaskException(
        code: 'task-not-found',
        message: 'Tugas tidak ditemukan.',
      );
    }
    if (task.isArchived) {
      throw const TaskException(
        code: 'task-already-archived',
        message: 'Tugas ini sudah diarsipkan.',
      );
    }

    try {
      await _taskRepository.archiveTask(
        workspaceId: workspaceId,
        taskId: taskId,
      );
    } on FirebaseException catch (e) {
      throw TaskException.fromFirebase(e);
    }
  }

  Future<void> unarchiveTask({
    required String workspaceId,
    required String taskId,
  }) async {
    await _requireActivePm(workspaceId);
    final task = await _taskRepository.getTask(workspaceId, taskId);
    if (task == null) {
      throw const TaskException(
        code: 'task-not-found',
        message: 'Tugas tidak ditemukan.',
      );
    }
    if (!task.isArchived) {
      throw const TaskException(
        code: 'task-not-archived',
        message: 'Tugas ini tidak sedang diarsipkan.',
      );
    }

    try {
      await _taskRepository.unarchiveTask(
        workspaceId: workspaceId,
        taskId: taskId,
      );
    } on FirebaseException catch (e) {
      throw TaskException.fromFirebase(e);
    }
  }
}
