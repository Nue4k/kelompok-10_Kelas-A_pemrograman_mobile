import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_collections.dart';
import '../../core/exceptions/workspace_exception.dart';
import '../../core/utils/invite_code_generator.dart';
import '../models/enums.dart';
import '../models/workspace_model.dart';

/// Repository for managing workspaces (`workspaces/{workspaceId}`)
/// and invite code mappings (`inviteCodes/{code}`).
class WorkspaceRepository {
  WorkspaceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _workspacesRef =>
      _firestore.collection(FirestoreCollections.workspaces);

  CollectionReference<Map<String, dynamic>> get _inviteCodesRef =>
      _firestore.collection(FirestoreCollections.inviteCodes);

  /// Creates a workspace, adds [createdBy] as an active PM member, and reserves
  /// a unique invite code atomically in a single Firestore transaction.
  Future<WorkspaceModel> createWorkspace({
    required String name,
    String? description,
    required String createdBy,
    String Function()? codeGenerator,
    int maxCodeRetries = 5,
  }) async {
    final trimmedName = name.trim();
    final trimmedDesc = description?.trim();
    final normalizedDesc =
        (trimmedDesc == null || trimmedDesc.isEmpty) ? null : trimmedDesc;
    final generateCode = codeGenerator ?? InviteCodeGenerator.generate;

    return _firestore.runTransaction((tx) async {
      String? uniqueCode;
      for (var attempt = 0; attempt < maxCodeRetries; attempt++) {
        final candidate = InviteCodeGenerator.normalize(generateCode());
        final codeSnap = await tx.get(_inviteCodesRef.doc(candidate));
        if (!codeSnap.exists) {
          uniqueCode = candidate;
          break;
        }
      }

      if (uniqueCode == null) {
        throw const WorkspaceException(
          code: 'invite-code-generation-failed',
          message: 'Gagal membuat kode undangan unik. Silakan coba lagi.',
        );
      }

      final workspaceRef = _workspacesRef.doc();
      final memberRef = workspaceRef
          .collection(FirestoreCollections.members)
          .doc(createdBy);
      final inviteCodeRef = _inviteCodesRef.doc(uniqueCode);

      tx.set(workspaceRef, {
        'workspaceName': trimmedName,
        'description': normalizedDesc,
        'inviteCode': uniqueCode,
        'status': WorkspaceStatus.active.value,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(memberRef, {
        'workspaceId': workspaceRef.id,
        'userId': createdBy,
        'role': MemberRole.pm.value,
        'status': MemberStatus.active.value,
        'joinedAt': FieldValue.serverTimestamp(),
        'removedAt': null,
      });

      tx.set(inviteCodeRef, {
        'workspaceId': workspaceRef.id,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return WorkspaceModel(
        id: workspaceRef.id,
        name: trimmedName,
        description: normalizedDesc,
        inviteCode: uniqueCode,
        status: WorkspaceStatus.active,
        createdBy: createdBy,
      );
    });
  }

  /// Fetches a workspace by [workspaceId], returning `null` if not found.
  Future<WorkspaceModel?> getWorkspaceById(String workspaceId) async {
    final doc = await _workspacesRef.doc(workspaceId).get();
    if (!doc.exists || doc.data() == null) return null;
    return WorkspaceModel.fromFirestore(doc);
  }

  /// Watches a workspace document in real time.
  Stream<WorkspaceModel?> watchWorkspace(String workspaceId) {
    return _workspacesRef.doc(workspaceId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return WorkspaceModel.fromFirestore(doc);
    });
  }

  /// Fetches all workspaces where [userId] is an active member.
  Future<List<WorkspaceModel>> getWorkspacesForUser(String userId) async {
    final memberSnap = await _firestore
        .collectionGroup(FirestoreCollections.members)
        .where('userId', isEqualTo: userId)
        .get();

    return _resolveWorkspacesFromMembers(memberSnap.docs);
  }

  /// Watches all workspaces where [userId] is an active member.
  Stream<List<WorkspaceModel>> watchWorkspacesForUser(String userId) {
    return _firestore
        .collectionGroup(FirestoreCollections.members)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snap) => _resolveWorkspacesFromMembers(snap.docs));
  }

  Future<List<WorkspaceModel>> _resolveWorkspacesFromMembers(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> memberDocs,
  ) async {
    final activeWorkspaceIds = memberDocs
        .where((doc) => doc.data()['status'] == MemberStatus.active.value)
        .map((doc) => doc.data()['workspaceId'] as String?)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (activeWorkspaceIds.isEmpty) return const [];

    final workspaces = await Future.wait(
      activeWorkspaceIds.map((id) async {
        try {
          return await getWorkspaceById(id);
        } on FirebaseException catch (e) {
          if (e.code == 'permission-denied') return null;
          rethrow;
        }
      }),
    );
    return workspaces.whereType<WorkspaceModel>().toList();
  }

  /// Resolves an invite code (plain or QR payload) to its `workspaceId`.
  Future<String?> resolveInviteCode(String code) async {
    final normalized = InviteCodeGenerator.extractCode(code);
    if (normalized.isEmpty) return null;

    final doc = await _inviteCodesRef.doc(normalized).get();
    if (!doc.exists || doc.data() == null) return null;
    return doc.data()!['workspaceId'] as String?;
  }

  /// Updates workspace metadata (`workspaceName`, `description`, `status`).
  Future<void> updateWorkspace({
    required String workspaceId,
    String? name,
    String? description,
    WorkspaceStatus? status,
    bool clearDescription = false,
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) {
      updates['workspaceName'] = name.trim();
    }

    if (clearDescription) {
      updates['description'] = null;
    } else if (description != null) {
      final trimmed = description.trim();
      updates['description'] = trimmed.isEmpty ? null : trimmed;
    }

    if (status != null) {
      updates['status'] = status.value;
    }

    if (updates.isEmpty) return;
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _workspacesRef.doc(workspaceId).update(updates);
  }

  /// Generates a new invite code, replaces the old `inviteCodes/{code}` entry,
  /// and updates the workspace document atomically in a transaction.
  Future<String> regenerateInviteCode({
    required String workspaceId,
    required String requestedBy,
    String Function()? codeGenerator,
    int maxCodeRetries = 5,
  }) async {
    final generateCode = codeGenerator ?? InviteCodeGenerator.generate;

    return _firestore.runTransaction((tx) async {
      final workspaceRef = _workspacesRef.doc(workspaceId);
      final workspaceSnap = await tx.get(workspaceRef);
      if (!workspaceSnap.exists || workspaceSnap.data() == null) {
        throw const WorkspaceException(
          code: 'workspace-not-found',
          message: 'Workspace tidak ditemukan.',
        );
      }

      final oldCode = workspaceSnap.data()!['inviteCode'] as String? ?? '';

      String? newCode;
      for (var attempt = 0; attempt < maxCodeRetries; attempt++) {
        final candidate = InviteCodeGenerator.normalize(generateCode());
        if (candidate == oldCode) continue;
        final codeSnap = await tx.get(_inviteCodesRef.doc(candidate));
        if (!codeSnap.exists) {
          newCode = candidate;
          break;
        }
      }

      if (newCode == null) {
        throw const WorkspaceException(
          code: 'invite-code-generation-failed',
          message: 'Gagal membuat kode undangan baru. Silakan coba lagi.',
        );
      }

      if (oldCode.isNotEmpty) {
        tx.delete(_inviteCodesRef.doc(oldCode));
      }

      tx.set(_inviteCodesRef.doc(newCode), {
        'workspaceId': workspaceId,
        'createdBy': requestedBy,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.update(workspaceRef, {
        'inviteCode': newCode,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return newCode;
    });
  }
}
