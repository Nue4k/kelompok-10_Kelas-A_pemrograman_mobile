import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/firestore_converters.dart';

class TaskAssignmentHistoryModel {
  const TaskAssignmentHistoryModel({
    required this.id,
    required this.taskId,
    this.oldPicId,
    required this.newPicId,
    required this.changedBy,
    this.reason,
    this.changedAt,
  });

  final String id;
  final String taskId;
  final String? oldPicId;
  final String newPicId;
  final String changedBy;
  final String? reason;
  final DateTime? changedAt;

  factory TaskAssignmentHistoryModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return TaskAssignmentHistoryModel(
      id: id,
      taskId: map['taskId'] as String? ?? '',
      oldPicId: map['oldPicId'] as String?,
      newPicId: map['newPicId'] as String? ?? '',
      changedBy: map['changedBy'] as String? ?? '',
      reason: map['reason'] as String?,
      changedAt: dateFromFirestore(map['changedAt']),
    );
  }

  factory TaskAssignmentHistoryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return TaskAssignmentHistoryModel.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'oldPicId': oldPicId,
      'newPicId': newPicId,
      'changedBy': changedBy,
      'reason': reason,
      'changedAt': dateToFirestore(changedAt),
    };
  }
}
