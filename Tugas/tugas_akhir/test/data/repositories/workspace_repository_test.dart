import 'package:creaflow/data/models/enums.dart';
import 'package:creaflow/data/repositories/workspace_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late WorkspaceRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = WorkspaceRepository(firestore: firestore);
  });

  group('WorkspaceRepository', () {
    test('createWorkspace creates workspace, PM member, and inviteCode',
        () async {
      final ws = await repository.createWorkspace(
        name: '  Tim Mobile  ',
        description: '  Proyek akhir  ',
        createdBy: 'pm-1',
        codeGenerator: () => 'abcd1234',
      );

      expect(ws.name, 'Tim Mobile');
      expect(ws.description, 'Proyek akhir');
      expect(ws.inviteCode, 'ABCD1234');
      expect(ws.status, WorkspaceStatus.active);

      final fetched = await repository.getWorkspaceById(ws.id);
      expect(fetched?.name, 'Tim Mobile');

      final memberDoc = await firestore
          .collection('workspaces')
          .doc(ws.id)
          .collection('members')
          .doc('pm-1')
          .get();
      expect(memberDoc.exists, isTrue);
      expect(memberDoc.data()?['role'], 'pm');
      expect(memberDoc.data()?['status'], 'active');

      expect(await repository.resolveInviteCode('ABCD1234'), ws.id);
      expect(
        await repository.resolveInviteCode('creaflow://join/abcd1234'),
        ws.id,
      );
      expect(await repository.resolveInviteCode('UNKNOWN9'), isNull);
    });

    test('updateWorkspace and regenerateInviteCode work cleanly', () async {
      final ws = await repository.createWorkspace(
        name: 'Tim A',
        description: 'Desc',
        createdBy: 'pm-1',
        codeGenerator: () => 'CODE1111',
      );

      await repository.updateWorkspace(
        workspaceId: ws.id,
        name: 'Tim A Baru',
        clearDescription: true,
        status: WorkspaceStatus.archived,
      );

      final updated = await repository.getWorkspaceById(ws.id);
      expect(updated!.name, 'Tim A Baru');
      expect(updated.description, isNull);
      expect(updated.status, WorkspaceStatus.archived);

      final newCode = await repository.regenerateInviteCode(
        workspaceId: ws.id,
        requestedBy: 'pm-1',
        codeGenerator: () => 'CODE2222',
      );
      expect(newCode, 'CODE2222');
      expect(await repository.resolveInviteCode('CODE1111'), isNull);
      expect(await repository.resolveInviteCode('CODE2222'), ws.id);
    });
  });
}
