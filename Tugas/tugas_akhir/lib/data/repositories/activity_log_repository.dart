import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_collections.dart';
import '../models/activity_log_model.dart';
import '../models/enums.dart';

/// Repository for managing workspace activity logs under
/// `workspaces/{workspaceId}/activityLogs/{logId}`.
class ActivityLogRepository {
  ActivityLogRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _logsRef(String workspaceId) =>
      _firestore
          .collection(FirestoreCollections.workspaces)
          .doc(workspaceId)
          .collection(FirestoreCollections.activityLogs);

  Future<ActivityLogModel> createLog({
    required String workspaceId,
    required String userId,
    String? taskId,
    required ActivityType activityType,
    required String description,
  }) async {
    final docRef = _logsRef(workspaceId).doc();
    await docRef.set({
      'workspaceId': workspaceId,
      'userId': userId,
      'taskId': taskId,
      'activityType': activityType.value,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return ActivityLogModel(
      id: docRef.id,
      workspaceId: workspaceId,
      userId: userId,
      taskId: taskId,
      activityType: activityType,
      description: description,
    );
  }

  Stream<List<ActivityLogModel>> watchActivityLogs(
    String workspaceId, {
    int limit = 50,
  }) {
    return _logsRef(workspaceId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(ActivityLogModel.fromFirestore).toList());
  }
}
