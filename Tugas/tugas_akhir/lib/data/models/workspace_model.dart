import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/firestore_converters.dart';
import 'enums.dart';

class WorkspaceModel {
  const WorkspaceModel({
    required this.id,
    required this.name,
    this.description,
    required this.inviteCode,
    required this.status,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final String inviteCode;
  final WorkspaceStatus status;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory WorkspaceModel.fromMap(String id, Map<String, dynamic> map) {
    return WorkspaceModel(
      id: id,
      name: map['workspaceName'] as String? ?? '',
      description: map['description'] as String?,
      inviteCode: map['inviteCode'] as String? ?? '',
      status: WorkspaceStatus.fromValue(map['status'] as String?),
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: dateFromFirestore(map['createdAt']),
      updatedAt: dateFromFirestore(map['updatedAt']),
    );
  }

  factory WorkspaceModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return WorkspaceModel.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      'workspaceName': name,
      'description': description,
      'inviteCode': inviteCode,
      'status': status.value,
      'createdBy': createdBy,
      'createdAt': dateToFirestore(createdAt),
      'updatedAt': dateToFirestore(updatedAt),
    };
  }
}
