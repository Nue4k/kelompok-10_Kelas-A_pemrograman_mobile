import 'package:firebase_auth/firebase_auth.dart';

import '../core/exceptions/task_exception.dart';
import '../core/utils/firestore_converters.dart';
import '../data/models/dashboard_summary_model.dart';
import '../data/models/enums.dart';
import '../data/models/task_filter.dart';
import '../data/models/task_model.dart';
import '../data/models/workspace_member_model.dart';
import '../data/repositories/dashboard_repository.dart';
import '../data/repositories/workspace_member_repository.dart';

/// Business-logic layer for workspace dashboard summaries and filtered task
/// lists.
class DashboardService {
  DashboardService({
    DashboardRepository? dashboardRepository,
    WorkspaceMemberRepository? memberRepository,
    FirebaseAuth? auth,
  })  : _dashboardRepository = dashboardRepository ?? DashboardRepository(),
        _memberRepository = memberRepository ?? WorkspaceMemberRepository(),
        _auth = auth ?? FirebaseAuth.instance;

  final DashboardRepository _dashboardRepository;
  final WorkspaceMemberRepository _memberRepository;
  final FirebaseAuth _auth;

  /// Validates [filter] before executing a query.
  static void validateFilter(TaskFilter filter) {
    if (filter.deadlineFrom != null && filter.deadlineTo != null) {
      final from = dateOnly(filter.deadlineFrom!);
      final to = dateOnly(filter.deadlineTo!);
      if (to.isBefore(from)) {
        throw const TaskException(
          code: 'invalid-date-range',
          message:
              'Tanggal akhir deadline tidak boleh lebih awal dari tanggal mulai.',
        );
      }
    }
  }

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const TaskException(
        code: 'unauthenticated',
        message: 'Silakan login terlebih dahulu.',
      );
    }
    return uid;
  }

  Future<WorkspaceMemberModel> _requireActiveMember(String workspaceId) async {
    final uid = _requireUid();
    final member = await _memberRepository.getMember(workspaceId, uid);
    if (member == null || member.status != MemberStatus.active) {
      throw const TaskException(
        code: 'permission-denied',
        message: 'Anda bukan anggota aktif workspace ini.',
      );
    }
    return member;
  }

  Future<DashboardSummaryModel> getWorkspaceDashboard(
    String workspaceId, {
    bool onlyMyTasks = false,
    DateTime? now,
  }) async {
    final member = await _requireActiveMember(workspaceId);
    try {
      return await _dashboardRepository.getWorkspaceSummary(
        workspaceId,
        picMemberId: onlyMyTasks ? member.userId : null,
        now: now,
      );
    } on FirebaseException catch (e) {
      throw TaskException.fromFirebase(e);
    }
  }

  Stream<T> _mapStreamErrors<T>(Stream<T> stream) {
    return stream.handleError((Object error, StackTrace stackTrace) {
      if (error is FirebaseException) {
        Error.throwWithStackTrace(
          TaskException.fromFirebase(error),
          stackTrace,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

  Stream<DashboardSummaryModel> watchWorkspaceDashboard(
    String workspaceId, {
    bool onlyMyTasks = false,
    DateTime? now,
  }) {
    final uid = _requireUid();
    return _mapStreamErrors(
      _dashboardRepository.watchWorkspaceSummary(
        workspaceId,
        picMemberId: onlyMyTasks ? uid : null,
        now: now,
      ),
    );
  }

  Future<List<TaskModel>> getFilteredTasks(
    String workspaceId, {
    TaskFilter filter = const TaskFilter(),
    DateTime? now,
  }) async {
    await _requireActiveMember(workspaceId);
    validateFilter(filter);
    try {
      return await _dashboardRepository.getFilteredTasks(
        workspaceId,
        filter: filter,
        now: now,
      );
    } on FirebaseException catch (e) {
      throw TaskException.fromFirebase(e);
    }
  }

  Stream<List<TaskModel>> watchFilteredTasks(
    String workspaceId, {
    TaskFilter filter = const TaskFilter(),
    DateTime? now,
  }) {
    _requireUid();
    validateFilter(filter);
    return _mapStreamErrors(
      _dashboardRepository.watchFilteredTasks(
        workspaceId,
        filter: filter,
        now: now,
      ),
    );
  }
}
