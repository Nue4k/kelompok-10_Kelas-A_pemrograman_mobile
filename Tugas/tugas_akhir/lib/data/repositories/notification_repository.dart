import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_collections.dart';
import '../models/enums.dart';
import '../models/notification_model.dart';

/// Repository for managing in-app notifications under
/// `users/{userId}/notifications/{notificationId}`.
class NotificationRepository {
  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _notificationsRef(String userId) =>
      _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .collection(FirestoreCollections.notifications);

  Future<NotificationModel> createNotification({
    required String userId,
    String? workspaceId,
    String? taskId,
    required NotificationType type,
    required String message,
  }) async {
    final docRef = _notificationsRef(userId).doc();
    await docRef.set({
      'userId': userId,
      'workspaceId': workspaceId,
      'taskId': taskId,
      'type': type.value,
      'message': message,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return NotificationModel(
      id: docRef.id,
      userId: userId,
      workspaceId: workspaceId,
      taskId: taskId,
      type: type,
      message: message,
      isRead: false,
    );
  }

  Stream<List<NotificationModel>> watchNotifications(
    String userId, {
    bool unreadOnly = false,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> query = _notificationsRef(userId);
    if (unreadOnly) {
      query = query.where('isRead', isEqualTo: false);
    }
    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(NotificationModel.fromFirestore).toList());
  }

  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) async {
    await _notificationsRef(userId).doc(notificationId).update({
      'isRead': true,
    });
  }

  Future<void> markAllAsRead(String userId) async {
    final unreadSnap = await _notificationsRef(userId)
        .where('isRead', isEqualTo: false)
        .get();
    if (unreadSnap.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unreadSnap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
