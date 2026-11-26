import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/firestore_converters.dart';
import 'enums.dart';

class ActivityLogModel {
  const ActivityLogModel({
    required this.id,
    required this.workspaceId,
    required this.userId,
    this.taskId,
    required this.activityType,
    required this.description,
    this.createdAt,
  });

  final String id;
  final String workspaceId;
  final String userId;
  final String? taskId;
  final ActivityType activityType;
  final String description;
  final DateTime? createdAt;

  factory ActivityLogModel.fromMap(String id, Map<String, dynamic> map) {
    return ActivityLogModel(
      id: id,
      workspaceId: map['workspaceId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      taskId: map['taskId'] as String?,
      activityType: ActivityType.fromValue(map['activityType'] as String?),
      description: map['description'] as String? ?? '',
      createdAt: dateFromFirestore(map['createdAt']),
    );
  }

  factory ActivityLogModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ActivityLogModel.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      'workspaceId': workspaceId,
      'userId': userId,
      'taskId': taskId,
      'activityType': activityType.value,
      'description': description,
      'createdAt': dateToFirestore(createdAt),
    };
  }
}
