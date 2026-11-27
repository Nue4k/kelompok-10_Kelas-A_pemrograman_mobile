import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_collections.dart';
import '../../core/utils/firestore_converters.dart';
import '../models/enums.dart';
import '../models/task_model.dart';

/// Repository for managing tasks under `workspaces/{workspaceId}/tasks/{taskId}`.
class TaskRepository {
  TaskRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _tasksRef(String workspaceId) =>
      _firestore
          .collection(FirestoreCollections.workspaces)
          .doc(workspaceId)
          .collection(FirestoreCollections.tasks);

  /// Creates a new task in `todo` status.
  Future<TaskModel> createTask({
    required String workspaceId,
    required String picMemberId,
    required String createdBy,
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? deadline,
    required TaskPriority priority,
  }) async {
    final docRef = _tasksRef(workspaceId).doc();
    await docRef.set({
      'workspaceId': workspaceId,
      'picMemberId': picMemberId,
      'createdBy': createdBy,
      'title': title,
      'description': description,
      'startDate': dateToFirestore(startDate),
      'deadline': dateToFirestore(deadline),
      'priority': priority.value,
      'status': TaskStatus.todo.value,
      'archivedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return TaskModel(
      id: docRef.id,
      workspaceId: workspaceId,
      picMemberId: picMemberId,
      createdBy: createdBy,
      title: title,
      description: description,
      startDate: startDate,
      deadline: deadline,
      priority: priority,
      status: TaskStatus.todo,
    );
  }

  /// Fetches a single task, returning `null` if not found.
  Future<TaskModel?> getTask(String workspaceId, String taskId) async {
    final doc = await _tasksRef(workspaceId).doc(taskId).get();
    if (!doc.exists || doc.data() == null) return null;
    return TaskModel.fromFirestore(doc);
  }

  /// Watches a single task in real time.
  Stream<TaskModel?> watchTask(String workspaceId, String taskId) {
    return _tasksRef(workspaceId).doc(taskId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return TaskModel.fromFirestore(doc);
    });
  }

  /// Fetches tasks in a workspace.
  Future<List<TaskModel>> getTasks(
    String workspaceId, {
    bool includeArchived = false,
  }) async {
    Query<Map<String, dynamic>> query = _tasksRef(workspaceId);
    if (!includeArchived) {
      query = query.where('archivedAt', isNull: true);
    }
    final snap = await query.get();
    return snap.docs.map(TaskModel.fromFirestore).toList();
  }

  /// Watches tasks in a workspace in real time.
  Stream<List<TaskModel>> watchTasks(
    String workspaceId, {
    bool includeArchived = false,
  }) {
    Query<Map<String, dynamic>> query = _tasksRef(workspaceId);
    if (!includeArchived) {
      query = query.where('archivedAt', isNull: true);
    }
    return query.snapshots().map(
          (snap) => snap.docs.map(TaskModel.fromFirestore).toList(),
        );
  }

  /// Updates editable fields of a task.
  Future<void> updateTask({
    required String workspaceId,
    required String taskId,
    String? title,
    String? description,
    bool clearDescription = false,
    String? picMemberId,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? deadline,
    bool clearDeadline = false,
    TaskPriority? priority,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (title != null) {
      updates['title'] = title;
    }
    if (clearDescription) {
      updates['description'] = null;
    } else if (description != null) {
      updates['description'] = description;
    }
    if (picMemberId != null) {
      updates['picMemberId'] = picMemberId;
    }
    if (clearStartDate) {
      updates['startDate'] = null;
    } else if (startDate != null) {
      updates['startDate'] = dateToFirestore(startDate);
    }
    if (clearDeadline) {
      updates['deadline'] = null;
    } else if (deadline != null) {
      updates['deadline'] = dateToFirestore(deadline);
    }
    if (priority != null) {
      updates['priority'] = priority.value;
    }

    await _tasksRef(workspaceId).doc(taskId).update(updates);
  }

  /// Updates the task status.
  Future<void> updateTaskStatus({
    required String workspaceId,
    required String taskId,
    required TaskStatus newStatus,
  }) async {
    await _tasksRef(workspaceId).doc(taskId).update({
      'status': newStatus.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Soft-archives a task by setting `archivedAt`.
  Future<void> archiveTask({
    required String workspaceId,
    required String taskId,
  }) async {
    await _tasksRef(workspaceId).doc(taskId).update({
      'archivedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Restores an archived task by clearing `archivedAt`.
  Future<void> unarchiveTask({
    required String workspaceId,
    required String taskId,
  }) async {
    await _tasksRef(workspaceId).doc(taskId).update({
      'archivedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
