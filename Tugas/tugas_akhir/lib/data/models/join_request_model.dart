import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/firestore_converters.dart';
import 'enums.dart';

/// Document ID is equal to [userId] (`workspaces/{workspaceId}/joinRequests/{userId}`).
class JoinRequestModel {
  const JoinRequestModel({
    required this.id,
    required this.workspaceId,
    required this.userId,
    required this.status,
    this.requestedAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  final String id;
  final String workspaceId;
  final String userId;
  final RequestStatus status;
  final DateTime? requestedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  factory JoinRequestModel.fromMap(String id, Map<String, dynamic> map) {
    return JoinRequestModel(
      id: id,
      workspaceId: map['workspaceId'] as String? ?? '',
      userId: map['userId'] as String? ?? id,
      status: RequestStatus.fromValue(map['status'] as String?),
      requestedAt: dateFromFirestore(map['requestedAt']),
      reviewedAt: dateFromFirestore(map['reviewedAt']),
      reviewedBy: map['reviewedBy'] as String?,
    );
  }

  factory JoinRequestModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return JoinRequestModel.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      'workspaceId': workspaceId,
      'userId': userId,
      'status': status.value,
      'requestedAt': dateToFirestore(requestedAt),
      'reviewedAt': dateToFirestore(reviewedAt),
      'reviewedBy': reviewedBy,
    };
  }
}
