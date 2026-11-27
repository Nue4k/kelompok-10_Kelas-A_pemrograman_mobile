import 'dart:math';

import 'package:creaflow/core/utils/invite_code_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InviteCodeGenerator', () {
    test('generates 8-character code by default using allowed alphabet', () {
      final code = InviteCodeGenerator.generate(random: Random(42));
      expect(code.length, InviteCodeGenerator.defaultLength);
      for (final ch in code.split('')) {
        expect(InviteCodeGenerator.alphabet.contains(ch), isTrue);
        expect(['0', 'O', '1', 'I'].contains(ch), isFalse);
      }
    });

    test('supports custom length and throws on non-positive length', () {
      final code = InviteCodeGenerator.generate(length: 12, random: Random(1));
      expect(code.length, 12);

      expect(() => InviteCodeGenerator.generate(length: 0), throwsArgumentError);
      expect(
        () => InviteCodeGenerator.generate(length: -3),
        throwsArgumentError,
      );
    });

    test('toQrPayload and extractCode round-trip cleanly', () {
      expect(
        InviteCodeGenerator.toQrPayload(' k7m9p2qx '),
        'creaflow://join/K7M9P2QX',
      );
      expect(
        InviteCodeGenerator.extractCode('creaflow://join/k7m9p2qx'),
        'K7M9P2QX',
      );
      expect(
        InviteCodeGenerator.extractCode('  CREAFLOW://JOIN/k7m9p2qx/?ref=qr  '),
        'K7M9P2QX',
      );
      expect(
        InviteCodeGenerator.extractCode('  k7m9p2qx  '),
        'K7M9P2QX',
      );
    });

    test('isValidFormat validates both plain codes and QR payloads', () {
      expect(InviteCodeGenerator.isValidFormat('K7M9P2QX'), isTrue);
      expect(
        InviteCodeGenerator.isValidFormat('creaflow://join/k7m9p2qx'),
        isTrue,
      );
      expect(InviteCodeGenerator.isValidFormat('K7M9P2Q'), isFalse);
      expect(InviteCodeGenerator.isValidFormat('K7M9P2Q0'), isFalse);
      expect(InviteCodeGenerator.isValidFormat('K7M9P2QO'), isFalse);
      expect(InviteCodeGenerator.isValidFormat('K7M9P2Q1'), isFalse);
      expect(InviteCodeGenerator.isValidFormat('K7M9P2QI'), isFalse);
    });
  });
}
