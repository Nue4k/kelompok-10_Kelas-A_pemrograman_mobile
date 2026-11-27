import 'package:creaflow/core/exceptions/workspace_exception.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkspaceException', () {
    test('toString formats code and message', () {
      const exception = WorkspaceException(
        code: 'invite-code-not-found',
        message: 'Kode undangan tidak ditemukan.',
      );
      expect(
        exception.toString(),
        'WorkspaceException(invite-code-not-found): Kode undangan tidak ditemukan.',
      );
    });

    test('fromFirebase maps known error codes to Indonesian messages', () {
      final permissionDenied = WorkspaceException.fromFirebase(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      expect(permissionDenied.code, 'permission-denied');
      expect(permissionDenied.message, contains('izin'));

      final notFound = WorkspaceException.fromFirebase(
        FirebaseException(plugin: 'cloud_firestore', code: 'not-found'),
      );
      expect(notFound.code, 'not-found');
      expect(notFound.message, contains('tidak ditemukan'));

      final unavailable = WorkspaceException.fromFirebase(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );
      expect(unavailable.code, 'unavailable');
      expect(unavailable.message, contains('koneksi'));

      final unknown = WorkspaceException.fromFirebase(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'custom-error',
          message: 'Custom',
        ),
      );
      expect(unknown.code, 'custom-error');
      expect(unknown.message, 'Custom');
    });
  });
}
