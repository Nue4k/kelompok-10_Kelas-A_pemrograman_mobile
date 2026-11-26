import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/firestore_converters.dart';

class TaskAttachmentModel {
  const TaskAttachmentModel({
    required this.id,
    required this.taskId,
    required this.uploadedBy,
    required this.fileUrl,
    this.uploadedAt,
  });

  final String id;
  final String taskId;
  final String uploadedBy;
  final String fileUrl;
  final DateTime? uploadedAt;

  factory TaskAttachmentModel.fromMap(String id, Map<String, dynamic> map) {
    return TaskAttachmentModel(
      id: id,
      taskId: map['taskId'] as String? ?? '',
      uploadedBy: map['uploadedBy'] as String? ?? '',
      fileUrl: map['fileUrl'] as String? ?? '',
      uploadedAt: dateFromFirestore(map['uploadedAt']),
    );
  }

  factory TaskAttachmentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return TaskAttachmentModel.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'uploadedBy': uploadedBy,
      'fileUrl': fileUrl,
      'uploadedAt': dateToFirestore(uploadedAt),
    };
  }
}
