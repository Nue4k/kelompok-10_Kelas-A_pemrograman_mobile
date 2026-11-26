import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/firestore_converters.dart';

class TaskCommentModel {
  const TaskCommentModel({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.commentText,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String taskId;
  final String userId;
  final String commentText;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TaskCommentModel.fromMap(String id, Map<String, dynamic> map) {
    return TaskCommentModel(
      id: id,
      taskId: map['taskId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      commentText: map['commentText'] as String? ?? '',
      createdAt: dateFromFirestore(map['createdAt']),
      updatedAt: dateFromFirestore(map['updatedAt']),
    );
  }

  factory TaskCommentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return TaskCommentModel.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'userId': userId,
      'commentText': commentText,
      'createdAt': dateToFirestore(createdAt),
      'updatedAt': dateToFirestore(updatedAt),
    };
  }
}
