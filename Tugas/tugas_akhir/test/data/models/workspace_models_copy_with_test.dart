import 'package:creaflow/data/models/enums.dart';
import 'package:creaflow/data/models/join_request_model.dart';
import 'package:creaflow/data/models/workspace_member_model.dart';
import 'package:creaflow/data/models/workspace_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Workspace models copyWith', () {
    test('WorkspaceModel.copyWith updates fields and clears description', () {
      const base = WorkspaceModel(
        id: 'ws-1',
        name: 'CreaFlow',
        description: 'Initial',
        inviteCode: 'K7M9P2QX',
        status: WorkspaceStatus.active,
        createdBy: 'uid-1',
      );

      final updated = base.copyWith(
        name: 'CreaFlow V2',
        status: WorkspaceStatus.archived,
        clearDescription: true,
      );

      expect(updated.id, 'ws-1');
      expect(updated.name, 'CreaFlow V2');
      expect(updated.description, isNull);
      expect(updated.status, WorkspaceStatus.archived);
      expect(updated.inviteCode, 'K7M9P2QX');
    });

    test('WorkspaceMemberModel.copyWith updates role and status', () {
      const base = WorkspaceMemberModel(
        id: 'uid-2',
        workspaceId: 'ws-1',
        userId: 'uid-2',
        role: MemberRole.member,
        status: MemberStatus.active,
      );

      final promoted = base.copyWith(role: MemberRole.pm);
      expect(promoted.role, MemberRole.pm);
      expect(promoted.isPm, isTrue);

      final removed = promoted.copyWith(
        status: MemberStatus.removed,
        removedAt: DateTime(2026, 11, 27),
      );
      expect(removed.status, MemberStatus.removed);
      expect(removed.removedAt, DateTime(2026, 11, 27));
    });

    test('JoinRequestModel.copyWith updates review status', () {
      const base = JoinRequestModel(
        id: 'uid-3',
        workspaceId: 'ws-1',
        userId: 'uid-3',
        status: RequestStatus.pending,
      );

      final approved = base.copyWith(
        status: RequestStatus.approved,
        reviewedBy: 'uid-1',
        reviewedAt: DateTime(2026, 11, 27),
      );

      expect(approved.status, RequestStatus.approved);
      expect(approved.reviewedBy, 'uid-1');
      expect(approved.reviewedAt, DateTime(2026, 11, 27));
    });
  });
}
