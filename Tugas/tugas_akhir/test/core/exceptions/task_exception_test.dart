import 'package:creaflow/core/exceptions/task_exception.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskException.fromFirebase', () {
    test('maps known FirebaseException codes to Indonesian messages', () {
      const cases = {
        'permission-denied':
            'Anda tidak memiliki izin untuk melakukan tindakan pada tugas ini.',
        'not-found': 'Data tugas tidak ditemukan.',
        'already-exists': 'Data tugas sudah ada.',
        'unavailable':
            'Layanan sedang tidak tersedia. Periksa koneksi internet Anda.',
        'deadline-exceeded': 'Permintaan melebihi batas waktu. Coba lagi.',
        'unauthenticated': 'Silakan login terlebih dahulu.',
      };

      cases.forEach((code, expectedMessage) {
        final ex = TaskException.fromFirebase(
          FirebaseException(plugin: 'cloud_firestore', code: code),
        );
        expect(ex.code, code);
        expect(ex.message, expectedMessage);
      });
    });

    test('falls back for unknown codes and formats toString', () {
      final ex = TaskException.fromFirebase(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'aborted',
          message: 'Transaction aborted',
        ),
      );
      expect(ex.code, 'aborted');
      expect(ex.message, 'Transaction aborted');
      expect(ex.toString(), 'TaskException(aborted): Transaction aborted');
    });
  });
}
