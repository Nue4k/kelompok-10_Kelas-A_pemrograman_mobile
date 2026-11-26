import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/firestore_converters.dart';
import 'enums.dart';

class PicChangeRequestModel {
  const PicChangeRequestModel({
    required this.id,
    required this.taskId,
    required this.requestedBy,
    required this.currentPicId,
    required this.proposedPicId,
    required this.status,
    this.reason,
    this.requestedAt,
    this.reviewedBy,
    this.reviewedAt,
  });

  final String id;
  final String taskId;
  final String requestedBy;
  final String currentPicId;
  final String proposedPicId;
  final RequestStatus status;
  final String? reason;
  final DateTime? requestedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  factory PicChangeRequestModel.fromMap(String id, Map<String, dynamic> map) {
    return PicChangeRequestModel(
      id: id,
      taskId: map['taskId'] as String? ?? '',
      requestedBy: map['requestedBy'] as String? ?? '',
      currentPicId: map['currentPicId'] as String? ?? '',
      proposedPicId: map['proposedPicId'] as String? ?? '',
      status: RequestStatus.fromValue(map['status'] as String?),
      reason: map['reason'] as String?,
      requestedAt: dateFromFirestore(map['requestedAt']),
      reviewedBy: map['reviewedBy'] as String?,
      reviewedAt: dateFromFirestore(map['reviewedAt']),
    );
  }

  factory PicChangeRequestModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return PicChangeRequestModel.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'requestedBy': requestedBy,
      'currentPicId': currentPicId,
      'proposedPicId': proposedPicId,
      'status': status.value,
      'reason': reason,
      'requestedAt': dateToFirestore(requestedAt),
      'reviewedBy': reviewedBy,
      'reviewedAt': dateToFirestore(reviewedAt),
    };
  }
}
