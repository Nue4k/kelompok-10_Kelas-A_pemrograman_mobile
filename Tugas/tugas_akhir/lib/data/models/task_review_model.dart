import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/firestore_converters.dart';
import 'enums.dart';

class TaskReviewModel {
  const TaskReviewModel({
    required this.id,
    required this.taskId,
    required this.submittedBy,
    this.reviewedBy,
    this.decision,
    this.feedback,
    this.submittedAt,
    this.reviewedAt,
  });

  final String id;
  final String taskId;
  final String submittedBy;
  final String? reviewedBy;
  final ReviewDecision? decision;
  final String? feedback;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  factory TaskReviewModel.fromMap(String id, Map<String, dynamic> map) {
    return TaskReviewModel(
      id: id,
      taskId: map['taskId'] as String? ?? '',
      submittedBy: map['submittedBy'] as String? ?? '',
      reviewedBy: map['reviewedBy'] as String?,
      decision: ReviewDecision.fromValue(map['decision'] as String?),
      feedback: map['feedback'] as String?,
      submittedAt: dateFromFirestore(map['submittedAt']),
      reviewedAt: dateFromFirestore(map['reviewedAt']),
    );
  }

  factory TaskReviewModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return TaskReviewModel.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'submittedBy': submittedBy,
      'reviewedBy': reviewedBy,
      'decision': decision?.value,
      'feedback': feedback,
      'submittedAt': dateToFirestore(submittedAt),
      'reviewedAt': dateToFirestore(reviewedAt),
    };
  }
}
