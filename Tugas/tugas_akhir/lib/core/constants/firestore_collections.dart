/// Firestore collection and subcollection path constants.
abstract final class FirestoreCollections {
  // Top-level collections
  static const String users = 'users';
  static const String workspaces = 'workspaces';
  static const String inviteCodes = 'inviteCodes';

  // User subcollections
  static const String notifications = 'notifications';

  // Workspace subcollections
  static const String members = 'members';
  static const String jobDescriptions = 'jobDescriptions';
  static const String joinRequests = 'joinRequests';
  static const String activityLogs = 'activityLogs';
  static const String tasks = 'tasks';

  // Task subcollections
  static const String attachments = 'attachments';
  static const String comments = 'comments';
  static const String statusHistory = 'statusHistory';
  static const String reviews = 'reviews';
  static const String contributors = 'contributors';
  static const String picChangeRequests = 'picChangeRequests';
  static const String assignmentHistory = 'assignmentHistory';
}
