import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_collections.dart';
import '../../core/exceptions/workspace_exception.dart';
import '../models/enums.dart';
import '../models/join_request_model.dart';
import '../models/workspace_member_model.dart';

/// Repository for managing workspace members (`workspaces/{id}/members/{uid}`)
/// and join requests (`workspaces/{id}/joinRequests/{uid}`).
class WorkspaceMemberRepository {
  WorkspaceMemberRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _membersRef(String workspaceId) =>
      _firestore
          .collection(FirestoreCollections.workspaces)
          .doc(workspaceId)
          .collection(FirestoreCollections.members);

  CollectionReference<Map<String, dynamic>> _joinRequestsRef(
    String workspaceId,
  ) =>
      _firestore
          .collection(FirestoreCollections.workspaces)
          .doc(workspaceId)
          .collection(FirestoreCollections.joinRequests);

  /// Fetches a single member document, returning `null` if not found.
  Future<WorkspaceMemberModel?> getMember(
    String workspaceId,
    String userId,
  ) async {
    final doc = await _membersRef(workspaceId).doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return WorkspaceMemberModel.fromFirestore(doc);
  }

  /// Fetches members of a workspace.
  Future<List<WorkspaceMemberModel>> getMembers(
    String workspaceId, {
    bool activeOnly = true,
  }) async {
    Query<Map<String, dynamic>> query = _membersRef(workspaceId);
    if (activeOnly) {
      query = query.where('status', isEqualTo: MemberStatus.active.value);
    }
    final snap = await query.get();
    return snap.docs.map(WorkspaceMemberModel.fromFirestore).toList();
  }

  /// Watches members of a workspace in real time.
  Stream<List<WorkspaceMemberModel>> watchMembers(
    String workspaceId, {
    bool activeOnly = true,
  }) {
    Query<Map<String, dynamic>> query = _membersRef(workspaceId);
    if (activeOnly) {
      query = query.where('status', isEqualTo: MemberStatus.active.value);
    }
    return query.snapshots().map(
          (snap) => snap.docs.map(WorkspaceMemberModel.fromFirestore).toList(),
        );
  }

  /// Updates a member's role (`pm` or `member`).
  Future<void> updateMemberRole({
    required String workspaceId,
    required String userId,
    required MemberRole newRole,
  }) async {
    await _membersRef(workspaceId).doc(userId).update({
      'role': newRole.value,
    });
  }

  /// Soft-removes a member by setting `status` to `removed` and `removedAt`.
  Future<void> removeMember({
    required String workspaceId,
    required String userId,
  }) async {
    await _membersRef(workspaceId).doc(userId).update({
      'status': MemberStatus.removed.value,
      'removedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Fetches a user's join request for a workspace, if any.
  Future<JoinRequestModel?> getJoinRequest(
    String workspaceId,
    String userId,
  ) async {
    final doc = await _joinRequestsRef(workspaceId).doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return JoinRequestModel.fromFirestore(doc);
  }

  /// Watches pending join requests ordered by `requestedAt` descending.
  Stream<List<JoinRequestModel>> watchPendingJoinRequests(String workspaceId) {
    return _joinRequestsRef(workspaceId)
        .where('status', isEqualTo: RequestStatus.pending.value)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(JoinRequestModel.fromFirestore).toList());
  }

  /// Creates a new pending join request, or resubmits a previously rejected one.
  Future<JoinRequestModel> createOrResubmitJoinRequest({
    required String workspaceId,
    required String userId,
  }) async {
    final ref = _joinRequestsRef(workspaceId).doc(userId);
    final existing = await ref.get();

    if (!existing.exists) {
      await ref.set({
        'workspaceId': workspaceId,
        'userId': userId,
        'status': RequestStatus.pending.value,
        'requestedAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'reviewedBy': null,
      });
    } else {
      final currentStatus = existing.data()?['status'] as String?;
      if (currentStatus == RequestStatus.pending.value) {
        throw const WorkspaceException(
          code: 'join-request-already-pending',
          message:
              'Permintaan bergabung Anda masih menunggu persetujuan PM.',
        );
      }
      await ref.update({
        'status': RequestStatus.pending.value,
        'requestedAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'reviewedBy': null,
      });
    }

    return JoinRequestModel(
      id: userId,
      workspaceId: workspaceId,
      userId: userId,
      status: RequestStatus.pending,
    );
  }

  /// Approves a pending join request and activates the user in `members/{userId}`
  /// atomically in a single Firestore transaction.
  Future<void> approveJoinRequest({
    required String workspaceId,
    required String userId,
    required String reviewedBy,
  }) async {
    await _firestore.runTransaction((tx) async {
      final requestRef = _joinRequestsRef(workspaceId).doc(userId);
      final requestSnap = await tx.get(requestRef);
      if (!requestSnap.exists || requestSnap.data() == null) {
        throw const WorkspaceException(
          code: 'join-request-not-found',
          message: 'Permintaan bergabung tidak ditemukan.',
        );
      }

      final currentStatus = requestSnap.data()!['status'] as String?;
      if (currentStatus != RequestStatus.pending.value) {
        throw const WorkspaceException(
          code: 'join-request-already-processed',
          message: 'Permintaan bergabung ini sudah diproses sebelumnya.',
        );
      }

      tx.update(requestRef, {
        'status': RequestStatus.approved.value,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': reviewedBy,
      });

      final memberRef = _membersRef(workspaceId).doc(userId);
      tx.set(memberRef, {
        'workspaceId': workspaceId,
        'userId': userId,
        'role': MemberRole.member.value,
        'status': MemberStatus.active.value,
        'joinedAt': FieldValue.serverTimestamp(),
        'removedAt': null,
      });
    });
  }

  /// Rejects a pending join request in a Firestore transaction.
  Future<void> rejectJoinRequest({
    required String workspaceId,
    required String userId,
    required String reviewedBy,
  }) async {
    await _firestore.runTransaction((tx) async {
      final requestRef = _joinRequestsRef(workspaceId).doc(userId);
      final requestSnap = await tx.get(requestRef);
      if (!requestSnap.exists || requestSnap.data() == null) {
        throw const WorkspaceException(
          code: 'join-request-not-found',
          message: 'Permintaan bergabung tidak ditemukan.',
        );
      }

      final currentStatus = requestSnap.data()!['status'] as String?;
      if (currentStatus != RequestStatus.pending.value) {
        throw const WorkspaceException(
          code: 'join-request-already-processed',
          message: 'Permintaan bergabung ini sudah diproses sebelumnya.',
        );
      }

      tx.update(requestRef, {
        'status': RequestStatus.rejected.value,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': reviewedBy,
      });
    });
  }
}
