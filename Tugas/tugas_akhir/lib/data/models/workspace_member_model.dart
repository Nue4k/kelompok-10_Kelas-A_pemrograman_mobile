import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/firestore_converters.dart';
import 'enums.dart';

/// Document ID is equal to [userId] (`workspaces/{workspaceId}/members/{userId}`).
class WorkspaceMemberModel {
  const WorkspaceMemberModel({
    required this.id,
    required this.workspaceId,
    required this.userId,
    required this.role,
    required this.status,
    this.joinedAt,
    this.removedAt,
  });

  final String id;
  final String workspaceId;
  final String userId;
  final MemberRole role;
  final MemberStatus status;
  final DateTime? joinedAt;
  final DateTime? removedAt;

  bool get isPm => role == MemberRole.pm;

  factory WorkspaceMemberModel.fromMap(String id, Map<String, dynamic> map) {
    return WorkspaceMemberModel(
      id: id,
      workspaceId: map['workspaceId'] as String? ?? '',
      userId: map['userId'] as String? ?? id,
      role: MemberRole.fromValue(map['role'] as String?),
      status: MemberStatus.fromValue(map['status'] as String?),
      joinedAt: dateFromFirestore(map['joinedAt']),
      removedAt: dateFromFirestore(map['removedAt']),
    );
  }

  factory WorkspaceMemberModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return WorkspaceMemberModel.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      'workspaceId': workspaceId,
      'userId': userId,
      'role': role.value,
      'status': status.value,
      'joinedAt': dateToFirestore(joinedAt),
      'removedAt': dateToFirestore(removedAt),
    };
  }
}
