import 'package:creaflow/core/exceptions/auth_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppAuthException.fromFirebase maps known error codes', () {
    final mapped = AppAuthException.fromFirebase(
      FirebaseAuthException(code: 'email-already-in-use'),
    );

    expect(mapped.code, 'email-already-in-use');
    expect(mapped.message, contains('Email sudah terdaftar'));
  });

  test('AppAuthException.fromFirebase uses fallback for unknown code', () {
    final mapped = AppAuthException.fromFirebase(
      FirebaseAuthException(code: 'some-unknown-code', message: 'Custom error'),
    );

    expect(mapped.code, 'some-unknown-code');
    expect(mapped.message, 'Custom error');
    expect(mapped.toString(), 'AppAuthException(some-unknown-code): Custom error');
  });
}
