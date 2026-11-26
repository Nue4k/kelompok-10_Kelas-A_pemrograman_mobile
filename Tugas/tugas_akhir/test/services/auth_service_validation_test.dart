import 'package:creaflow/core/exceptions/auth_exception.dart';
import 'package:creaflow/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthService.validateRegisterInput', () {
    test('accepts valid input', () {
      expect(
        () => AuthService.validateRegisterInput(
          fullName: 'Akhmad Zaki',
          email: 'zaki@example.com',
          password: 'password123',
        ),
        returnsNormally,
      );
    });

    test('throws on empty fullName', () {
      expect(
        () => AuthService.validateRegisterInput(
          fullName: '   ',
          email: 'zaki@example.com',
          password: 'password123',
        ),
        throwsA(
          isA<AppAuthException>().having(
            (e) => e.code,
            'code',
            'invalid-full-name',
          ),
        ),
      );
    });

    test('throws on invalid email', () {
      expect(
        () => AuthService.validateRegisterInput(
          fullName: 'Akhmad Zaki',
          email: 'not-an-email',
          password: 'password123',
        ),
        throwsA(
          isA<AppAuthException>().having((e) => e.code, 'code', 'invalid-email'),
        ),
      );
    });

    test('throws on short password', () {
      expect(
        () => AuthService.validateRegisterInput(
          fullName: 'Akhmad Zaki',
          email: 'zaki@example.com',
          password: '123',
        ),
        throwsA(
          isA<AppAuthException>().having((e) => e.code, 'code', 'weak-password'),
        ),
      );
    });
  });

  group('AuthService.validateLoginInput', () {
    test('accepts valid input', () {
      expect(
        () => AuthService.validateLoginInput(
          email: 'zaki@example.com',
          password: 'secret',
        ),
        returnsNormally,
      );
    });

    test('throws on empty password', () {
      expect(
        () => AuthService.validateLoginInput(
          email: 'zaki@example.com',
          password: '',
        ),
        throwsA(
          isA<AppAuthException>().having((e) => e.code, 'code', 'empty-password'),
        ),
      );
    });
  });
}
