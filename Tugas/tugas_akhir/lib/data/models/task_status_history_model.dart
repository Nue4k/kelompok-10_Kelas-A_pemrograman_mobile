import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/firestore_converters.dart';
import 'enums.dart';

class TaskStatusHistoryModel {
  const TaskStatusHistoryModel({
    required this.id,
    required this.taskId,
    required this.changedBy,
    this.oldStatus,
    required this.newStatus,
    this.notes,
    this.changedAt,
  });

  final String id;
  final String taskId;
  final String changedBy;
  final TaskStatus? oldStatus;
  final TaskStatus newStatus;
  final String? notes;
  final DateTime? changedAt;

  factory TaskStatusHistoryModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    final rawOld = map['oldStatus'] as String?;
    return TaskStatusHistoryModel(
      id: id,
      taskId: map['taskId'] as String? ?? '',
      changedBy: map['changedBy'] as String? ?? '',
      oldStatus: rawOld == null ? null : TaskStatus.fromValue(rawOld),
      newStatus: TaskStatus.fromValue(map['newStatus'] as String?),
      notes: map['notes'] as String?,
      changedAt: dateFromFirestore(map['changedAt']),
    );
  }

  factory TaskStatusHistoryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return TaskStatusHistoryModel.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'changedBy': changedBy,
      'oldStatus': oldStatus?.value,
      'newStatus': newStatus.value,
      'notes': notes,
      'changedAt': dateToFirestore(changedAt),
    };
  }
}
