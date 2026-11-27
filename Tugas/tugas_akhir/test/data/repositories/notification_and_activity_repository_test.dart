import 'package:creaflow/data/models/enums.dart';
import 'package:creaflow/data/repositories/activity_log_repository.dart';
import 'package:creaflow/data/repositories/notification_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late NotificationRepository notificationRepo;
  late ActivityLogRepository activityRepo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    notificationRepo = NotificationRepository(firestore: firestore);
    activityRepo = ActivityLogRepository(firestore: firestore);
  });

  group('NotificationRepository & ActivityLogRepository', () {
    test('createNotification, watchNotifications, markAsRead, markAllAsRead',
        () async {
      final n1 = await notificationRepo.createNotification(
        userId: 'u-1',
        workspaceId: 'ws-1',
        type: NotificationType.taskAssigned,
        message: 'Tugas baru',
      );
      await notificationRepo.createNotification(
        userId: 'u-1',
        workspaceId: 'ws-1',
        type: NotificationType.commentAdded,
        message: 'Komentar baru',
      );

      final all = await notificationRepo.watchNotifications('u-1').first;
      expect(all, hasLength(2));

      await notificationRepo.markAsRead(userId: 'u-1', notificationId: n1.id);
      final unread = await notificationRepo
          .watchNotifications('u-1', unreadOnly: true)
          .first;
      expect(unread, hasLength(1));

      await notificationRepo.markAllAsRead('u-1');
      final unreadAfter = await notificationRepo
          .watchNotifications('u-1', unreadOnly: true)
          .first;
      expect(unreadAfter, isEmpty);
    });

    test('createLog and watchActivityLogs', () async {
      await activityRepo.createLog(
        workspaceId: 'ws-1',
        userId: 'pm-1',
        activityType: ActivityType.taskCreated,
        description: 'PM membuat tugas',
      );

      final logs = await activityRepo.watchActivityLogs('ws-1').first;
      expect(logs, hasLength(1));
      expect(logs.first.description, 'PM membuat tugas');
    });
  });
}
