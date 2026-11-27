import 'package:creaflow/core/exceptions/workspace_exception.dart';
import 'package:creaflow/services/workspace_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkspaceService validation', () {
    test('validateWorkspaceName trims valid names and rejects invalid ones', () {
      expect(
        WorkspaceService.validateWorkspaceName('  Tim Desain  '),
        'Tim Desain',
      );

      expect(
        () => WorkspaceService.validateWorkspaceName('   '),
        throwsA(
          isA<WorkspaceException>().having(
            (e) => e.code,
            'code',
            'invalid-workspace-name',
          ),
        ),
      );

      expect(
        () => WorkspaceService.validateWorkspaceName('a' * 101),
        throwsA(
          isA<WorkspaceException>().having(
            (e) => e.code,
            'code',
            'invalid-workspace-name',
          ),
        ),
      );
    });

    test('validateDescription normalizes empty to null and enforces max 500',
        () {
      expect(WorkspaceService.validateDescription(null), isNull);
      expect(WorkspaceService.validateDescription('   '), isNull);
      expect(
        WorkspaceService.validateDescription('  Deskripsi proyek  '),
        'Deskripsi proyek',
      );

      expect(
        () => WorkspaceService.validateDescription('a' * 501),
        throwsA(
          isA<WorkspaceException>().having(
            (e) => e.code,
            'code',
            'invalid-workspace-description',
          ),
        ),
      );
    });

    test('validateInviteCode accepts plain and QR payload, rejects invalid',
        () {
      expect(
        WorkspaceService.validateInviteCode(' k7m9p2qx '),
        'K7M9P2QX',
      );
      expect(
        WorkspaceService.validateInviteCode('creaflow://join/k7m9p2qx'),
        'K7M9P2QX',
      );

      expect(
        () => WorkspaceService.validateInviteCode('SHORT'),
        throwsA(
          isA<WorkspaceException>().having(
            (e) => e.code,
            'code',
            'invalid-invite-code',
          ),
        ),
      );
    });
  });
}
