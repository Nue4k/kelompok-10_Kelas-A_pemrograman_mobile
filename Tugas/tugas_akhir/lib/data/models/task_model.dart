import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/firestore_converters.dart';
import 'enums.dart';

class TaskModel {
  const TaskModel({
    required this.id,
    required this.workspaceId,
    required this.picMemberId,
    required this.createdBy,
    required this.title,
    this.description,
    this.startDate,
    this.deadline,
    required this.priority,
    required this.status,
    this.archivedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String workspaceId;

  /// Member's `userId` (since `members` doc ID == `userId`).
  final String picMemberId;
  final String createdBy;
  final String title;
  final String? description;
  final DateTime? startDate;
  final DateTime? deadline;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? archivedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isArchived => archivedAt != null;

  bool get isOverdue {
    if (deadline == null || status == TaskStatus.done || isArchived) {
      return false;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(deadline!.year, deadline!.month, deadline!.day);
    return dueDate.isBefore(today);
  }

  factory TaskModel.fromMap(String id, Map<String, dynamic> map) {
    return TaskModel(
      id: id,
      workspaceId: map['workspaceId'] as String? ?? '',
      picMemberId: map['picMemberId'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      startDate: dateFromFirestore(map['startDate']),
      deadline: dateFromFirestore(map['deadline']),
      priority: TaskPriority.fromValue(map['priority'] as String?),
      status: TaskStatus.fromValue(map['status'] as String?),
      archivedAt: dateFromFirestore(map['archivedAt']),
      createdAt: dateFromFirestore(map['createdAt']),
      updatedAt: dateFromFirestore(map['updatedAt']),
    );
  }

  factory TaskModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return TaskModel.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      'workspaceId': workspaceId,
      'picMemberId': picMemberId,
      'createdBy': createdBy,
      'title': title,
      'description': description,
      'startDate': dateToFirestore(startDate),
      'deadline': dateToFirestore(deadline),
      'priority': priority.value,
      'status': status.value,
      'archivedAt': dateToFirestore(archivedAt),
      'createdAt': dateToFirestore(createdAt),
      'updatedAt': dateToFirestore(updatedAt),
    };
  }
}
