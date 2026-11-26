enum WorkspaceStatus {
  active('active'),
  archived('archived');

  const WorkspaceStatus(this.value);
  final String value;

  static WorkspaceStatus fromValue(String? value) {
    return WorkspaceStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WorkspaceStatus.active,
    );
  }
}

enum MemberRole {
  pm('pm'),
  member('member');

  const MemberRole(this.value);
  final String value;

  static MemberRole fromValue(String? value) {
    return MemberRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MemberRole.member,
    );
  }
}

enum MemberStatus {
  active('active'),
  removed('removed');

  const MemberStatus(this.value);
  final String value;

  static MemberStatus fromValue(String? value) {
    return MemberStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MemberStatus.active,
    );
  }
}

enum RequestStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  const RequestStatus(this.value);
  final String value;

  static RequestStatus fromValue(String? value) {
    return RequestStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RequestStatus.pending,
    );
  }
}

enum TaskPriority {
  low('low'),
  medium('medium'),
  high('high');

  const TaskPriority(this.value);
  final String value;

  static TaskPriority fromValue(String? value) {
    return TaskPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskPriority.medium,
    );
  }
}

enum TaskStatus {
  todo('todo'),
  inProgress('in_progress'),
  inReview('in_review'),
  revision('revision'),
  done('done');

  const TaskStatus(this.value);
  final String value;

  static TaskStatus fromValue(String? value) {
    return TaskStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskStatus.todo,
    );
  }
}

enum ReviewDecision {
  approved('approved'),
  revision('revision');

  const ReviewDecision(this.value);
  final String value;

  static ReviewDecision? fromValue(String? value) {
    if (value == null) return null;
    for (final item in ReviewDecision.values) {
      if (item.value == value) return item;
    }
    return null;
  }
}

enum NotificationType {
  taskAssigned('task_assigned'),
  taskUpdated('task_updated'),
  reviewRequested('review_requested'),
  taskApproved('task_approved'),
  revisionRequested('revision_requested'),
  deadlineReminder('deadline_reminder'),
  taskOverdue('task_overdue'),
  joinRequested('join_requested'),
  joinApproved('join_approved'),
  joinRejected('join_rejected'),
  picChangeRequested('pic_change_requested'),
  commentAdded('comment_added');

  const NotificationType(this.value);
  final String value;

  static NotificationType fromValue(String? value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationType.taskUpdated,
    );
  }
}

enum ActivityType {
  workspaceCreated('workspace_created'),
  memberJoined('member_joined'),
  memberRemoved('member_removed'),
  taskCreated('task_created'),
  taskUpdated('task_updated'),
  taskStatusChanged('task_status_changed'),
  taskReviewed('task_reviewed'),
  picChanged('pic_changed'),
  commentAdded('comment_added'),
  attachmentAdded('attachment_added');

  const ActivityType(this.value);
  final String value;

  static ActivityType fromValue(String? value) {
    return ActivityType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ActivityType.taskUpdated,
    );
  }
}
