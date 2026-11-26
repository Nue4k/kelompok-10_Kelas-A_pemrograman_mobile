import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/firestore_converters.dart';
import 'enums.dart';

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    this.workspaceId,
    this.taskId,
    required this.type,
    required this.message,
    required this.isRead,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String? workspaceId;
  final String? taskId;
  final NotificationType type;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return NotificationModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      workspaceId: map['workspaceId'] as String?,
      taskId: map['taskId'] as String?,
      type: NotificationType.fromValue(map['type'] as String?),
      message: map['message'] as String? ?? '',
      isRead: map['isRead'] as bool? ?? false,
      createdAt: dateFromFirestore(map['createdAt']),
    );
  }

  factory NotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return NotificationModel.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'workspaceId': workspaceId,
      'taskId': taskId,
      'type': type.value,
      'message': message,
      'isRead': isRead,
      'createdAt': dateToFirestore(createdAt),
    };
  }
}
