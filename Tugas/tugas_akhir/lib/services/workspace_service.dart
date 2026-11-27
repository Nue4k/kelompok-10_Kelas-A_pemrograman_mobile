import 'package:firebase_auth/firebase_auth.dart';

import '../core/exceptions/workspace_exception.dart';
import '../core/utils/invite_code_generator.dart';
import '../data/models/enums.dart';
import '../data/models/join_request_model.dart';
import '../data/models/workspace_member_model.dart';
import '../data/models/workspace_model.dart';
import '../data/repositories/workspace_member_repository.dart';
import '../data/repositories/workspace_repository.dart';

/// Service coordinating workspace creation, invite-code joining,
/// join request approval/rejection, and member role management.
class WorkspaceService {
  WorkspaceService({
    FirebaseAuth? auth,
    WorkspaceRepository? workspaceRepository,
    WorkspaceMemberRepository? memberRepository,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _workspaceRepository = workspaceRepository ?? WorkspaceRepository(),
        _memberRepository = memberRepository ?? WorkspaceMemberRepository();

  final FirebaseAuth _auth;
  final WorkspaceRepository _workspaceRepository;
  final WorkspaceMemberRepository _memberRepository;

  static String validateWorkspaceName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 100) {
      throw const WorkspaceException(
        code: 'invalid-workspace-name',
        message: 'Nama workspace harus diisi dan maksimal 100 karakter.',
      );
    }
    return trimmed;
  }

  static String? validateDescription(String? description) {
    if (description == null) return null;
    final trimmed = description.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length > 500) {
      throw const WorkspaceException(
        code: 'invalid-workspace-description',
        message: 'Deskripsi workspace maksimal 500 karakter.',
      );
    }
    return trimmed;
  }

  static String validateInviteCode(String rawInput) {
    final code = InviteCodeGenerator.extractCode(rawInput);
    if (!InviteCodeGenerator.isValidFormat(code)) {
      throw const WorkspaceException(
        code: 'invalid-invite-code',
        message: 'Format kode undangan tidak valid (harus 8 karakter).',
      );
    }
    return code;
  }

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const WorkspaceException(
        code: 'unauthenticated',
        message: 'Silakan login terlebih dahulu.',
      );
    }
    return uid;
  }

  Future<String> _requireActivePm(String workspaceId) async {
    final uid = _requireUid();
    final member = await _memberRepository.getMember(workspaceId, uid);
    if (member == null ||
        member.status != MemberStatus.active ||
        !member.isPm) {
      throw const WorkspaceException(
        code: 'permission-denied',
        message: 'Hanya PM aktif yang dapat melakukan tindakan ini.',
      );
    }
    return uid;
  }

  Future<void> _ensureNotLastPm(
    String workspaceId,
    String targetUserId,
  ) async {
    final activeMembers = await _memberRepository.getMembers(
      workspaceId,
      activeOnly: true,
    );
    final activePms = activeMembers.where((m) => m.isPm).toList();
    final isTargetPm = activePms.any((m) => m.userId == targetUserId);
    if (isTargetPm && activePms.length <= 1) {
      throw const WorkspaceException(
        code: 'last-pm-protected',
        message:
            'Workspace harus memiliki minimal 1 PM aktif. Tunjuk PM lain terlebih dahulu.',
      );
    }
  }

  Future<WorkspaceModel> createWorkspace({
    required String name,
    String? description,
  }) async {
    final uid = _requireUid();
    final validName = validateWorkspaceName(name);
    final validDescription = validateDescription(description);

    try {
      return await _workspaceRepository.createWorkspace(
        name: validName,
        description: validDescription,
        createdBy: uid,
      );
    } on FirebaseException catch (e) {
      throw WorkspaceException.fromFirebase(e);
    }
  }

  Future<WorkspaceModel?> getWorkspaceById(String workspaceId) {
    _requireUid();
    return _workspaceRepository.getWorkspaceById(workspaceId);
  }

  Stream<WorkspaceModel?> watchWorkspace(String workspaceId) {
    _requireUid();
    return _workspaceRepository.watchWorkspace(workspaceId);
  }

  Future<List<WorkspaceModel>> getMyWorkspaces() {
    final uid = _requireUid();
    return _workspaceRepository.getWorkspacesForUser(uid);
  }

  Stream<List<WorkspaceModel>> watchMyWorkspaces() {
    final uid = _requireUid();
    return _workspaceRepository.watchWorkspacesForUser(uid);
  }

  Future<void> updateWorkspace({
    required String workspaceId,
    String? name,
    String? description,
    WorkspaceStatus? status,
    bool clearDescription = false,
  }) async {
    await _requireActivePm(workspaceId);
    final validName = name != null ? validateWorkspaceName(name) : null;
    final validDesc =
        clearDescription ? null : validateDescription(description);

    try {
      await _workspaceRepository.updateWorkspace(
        workspaceId: workspaceId,
        name: validName,
        description: validDesc,
        status: status,
        clearDescription: clearDescription,
      );
    } on FirebaseException catch (e) {
      throw WorkspaceException.fromFirebase(e);
    }
  }

  Future<String> regenerateInviteCode(String workspaceId) async {
    final uid = await _requireActivePm(workspaceId);
    try {
      return await _workspaceRepository.regenerateInviteCode(
        workspaceId: workspaceId,
        requestedBy: uid,
      );
    } on FirebaseException catch (e) {
      throw WorkspaceException.fromFirebase(e);
    }
  }

  /// Submits a join request using either a manual invite code or QR payload.
  Future<JoinRequestModel> joinWorkspaceByCode(String rawCode) async {
    final uid = _requireUid();
    final code = validateInviteCode(rawCode);

    try {
      final workspaceId = await _workspaceRepository.resolveInviteCode(code);
      if (workspaceId == null || workspaceId.isEmpty) {
        throw const WorkspaceException(
          code: 'invite-code-not-found',
          message: 'Kode undangan tidak ditemukan atau sudah tidak berlaku.',
        );
      }

      final existingMember = await _memberRepository.getMember(workspaceId, uid);
      if (existingMember != null &&
          existingMember.status == MemberStatus.active) {
        throw const WorkspaceException(
          code: 'already-member',
          message: 'Anda sudah menjadi anggota workspace ini.',
        );
      }

      return await _memberRepository.createOrResubmitJoinRequest(
        workspaceId: workspaceId,
        userId: uid,
      );
    } on FirebaseException catch (e) {
      throw WorkspaceException.fromFirebase(e);
    }
  }

  Stream<List<JoinRequestModel>> watchPendingJoinRequests(String workspaceId) {
    _requireUid();
    return _memberRepository.watchPendingJoinRequests(workspaceId);
  }

  Future<void> approveJoinRequest({
    required String workspaceId,
    required String userId,
  }) async {
    final pmUid = await _requireActivePm(workspaceId);
    try {
      await _memberRepository.approveJoinRequest(
        workspaceId: workspaceId,
        userId: userId,
        reviewedBy: pmUid,
      );
    } on FirebaseException catch (e) {
      throw WorkspaceException.fromFirebase(e);
    }
  }

  Future<void> rejectJoinRequest({
    required String workspaceId,
    required String userId,
  }) async {
    final pmUid = await _requireActivePm(workspaceId);
    try {
      await _memberRepository.rejectJoinRequest(
        workspaceId: workspaceId,
        userId: userId,
        reviewedBy: pmUid,
      );
    } on FirebaseException catch (e) {
      throw WorkspaceException.fromFirebase(e);
    }
  }

  Future<List<WorkspaceMemberModel>> getMembers(
    String workspaceId, {
    bool activeOnly = true,
  }) {
    _requireUid();
    return _memberRepository.getMembers(workspaceId, activeOnly: activeOnly);
  }

  Stream<List<WorkspaceMemberModel>> watchMembers(
    String workspaceId, {
    bool activeOnly = true,
  }) {
    _requireUid();
    return _memberRepository.watchMembers(workspaceId, activeOnly: activeOnly);
  }

  Future<void> changeMemberRole({
    required String workspaceId,
    required String userId,
    required MemberRole newRole,
  }) async {
    await _requireActivePm(workspaceId);
    if (newRole != MemberRole.pm) {
      await _ensureNotLastPm(workspaceId, userId);
    }
    try {
      await _memberRepository.updateMemberRole(
        workspaceId: workspaceId,
        userId: userId,
        newRole: newRole,
      );
    } on FirebaseException catch (e) {
      throw WorkspaceException.fromFirebase(e);
    }
  }

  Future<void> removeMember({
    required String workspaceId,
    required String userId,
  }) async {
    await _requireActivePm(workspaceId);
    await _ensureNotLastPm(workspaceId, userId);
    try {
      await _memberRepository.removeMember(
        workspaceId: workspaceId,
        userId: userId,
      );
    } on FirebaseException catch (e) {
      throw WorkspaceException.fromFirebase(e);
    }
  }

  Future<void> leaveWorkspace(String workspaceId) async {
    final uid = _requireUid();
    final member = await _memberRepository.getMember(workspaceId, uid);
    if (member == null || member.status != MemberStatus.active) {
      throw const WorkspaceException(
        code: 'not-a-member',
        message: 'Anda bukan anggota aktif workspace ini.',
      );
    }
    await _ensureNotLastPm(workspaceId, uid);
    try {
      await _memberRepository.removeMember(
        workspaceId: workspaceId,
        userId: uid,
      );
    } on FirebaseException catch (e) {
      throw WorkspaceException.fromFirebase(e);
    }
  }
}
