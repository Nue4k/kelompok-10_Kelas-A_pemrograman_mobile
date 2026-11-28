import 'package:firebase_auth/firebase_auth.dart';

import '../core/exceptions/notification_exception.dart';
import '../core/utils/deadline_reminder_checker.dart';
import '../data/models/activity_log_model.dart';
import '../data/models/notification_model.dart';
import '../data/models/task_model.dart';
import '../data/repositories/activity_log_repository.dart';
import '../data/repositories/notification_repository.dart';

/// Service for user in-app notifications, workspace activity logs, and
/// client-side deadline/overdue reminder checks.
class NotificationService {
  NotificationService({
    NotificationRepository? notificationRepository,
    ActivityLogRepository? activityLogRepository,
    FirebaseAuth? auth,
  })  : _notificationRepository =
            notificationRepository ?? NotificationRepository(),
        _activityLogRepository =
            activityLogRepository ?? ActivityLogRepository(),
        _auth = auth ?? FirebaseAuth.instance;

  final NotificationRepository _notificationRepository;
  final ActivityLogRepository _activityLogRepository;
  final FirebaseAuth _auth;

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const NotificationException(
        code: 'unauthenticated',
        message: 'Silakan login terlebih dahulu.',
      );
    }
    return uid;
  }

  Stream<T> _mapStreamErrors<T>(Stream<T> stream) {
    return stream.handleError((Object error, StackTrace stackTrace) {
      if (error is FirebaseException) {
        Error.throwWithStackTrace(
          NotificationException.fromFirebase(error),
          stackTrace,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

  Stream<List<NotificationModel>> watchMyNotifications({
    bool unreadOnly = false,
    int limit = 50,
  }) {
    final uid = _requireUid();
    return _mapStreamErrors(
      _notificationRepository.watchNotifications(
        uid,
        unreadOnly: unreadOnly,
        limit: limit,
      ),
    );
  }

  Future<void> markAsRead(String notificationId) async {
    final uid = _requireUid();
    try {
      await _notificationRepository.markAsRead(
        userId: uid,
        notificationId: notificationId,
      );
    } on FirebaseException catch (e) {
      throw NotificationException.fromFirebase(e);
    }
  }

  Future<void> markAllAsRead() async {
    final uid = _requireUid();
    try {
      await _notificationRepository.markAllAsRead(uid);
    } on FirebaseException catch (e) {
      throw NotificationException.fromFirebase(e);
    }
  }

  Stream<List<ActivityLogModel>> watchWorkspaceActivityLogs(
    String workspaceId, {
    int limit = 50,
  }) {
    _requireUid();
    return _mapStreamErrors(
      _activityLogRepository.watchActivityLogs(workspaceId, limit: limit),
    );
  }

  DeadlineReminderResult checkDeadlineReminders(
    Iterable<TaskModel> tasks, {
    DateTime? now,
  }) {
    return DeadlineReminderChecker.check(tasks, now: now);
  }
}
