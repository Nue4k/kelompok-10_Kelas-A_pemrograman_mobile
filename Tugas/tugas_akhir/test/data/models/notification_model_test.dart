import 'package:creaflow/data/models/enums.dart';
import 'package:creaflow/data/models/notification_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NotificationModel round-trip and missing isRead defaults to false', () {
    final notif = NotificationModel(
      id: 'n-1',
      userId: 'u-1',
      workspaceId: 'ws-1',
      taskId: 't-1',
      type: NotificationType.taskAssigned,
      message: 'You were assigned a task',
      isRead: true,
      createdAt: DateTime(2026, 11, 26),
    );

    final restored = NotificationModel.fromMap('n-1', notif.toMap());
    expect(restored.id, 'n-1');
    expect(restored.type, NotificationType.taskAssigned);
    expect(restored.isRead, isTrue);

    final missingIsRead = NotificationModel.fromMap('n-2', {
      'userId': 'u-1',
      'type': 'task_updated',
      'message': 'Task updated',
    });
    expect(missingIsRead.isRead, isFalse);
  });
}
