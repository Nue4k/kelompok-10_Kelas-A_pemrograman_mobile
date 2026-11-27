import 'package:creaflow/core/exceptions/notification_exception.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationException.fromFirebase', () {
    test('maps known codes to Indonesian messages', () {
      final ex = NotificationException.fromFirebase(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      expect(ex.code, 'permission-denied');
      expect(
        ex.message,
        'Anda tidak memiliki izin untuk mengakses notifikasi atau log ini.',
      );
      expect(
        ex.toString(),
        'NotificationException(permission-denied): Anda tidak memiliki izin untuk mengakses notifikasi atau log ini.',
      );
    });

    test('uses fallback for unknown code', () {
      final ex = NotificationException.fromFirebase(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'internal',
          message: 'Server error',
        ),
      );
      expect(ex.code, 'internal');
      expect(ex.message, 'Server error');
    });
  });
}
