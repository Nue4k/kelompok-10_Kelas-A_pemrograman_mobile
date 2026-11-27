import 'dart:math';

/// Utility for generating, normalizing, and parsing workspace invite codes
/// and their QR payloads.
abstract final class InviteCodeGenerator {
  static const int defaultLength = 8;

  /// Excludes visually ambiguous characters (`0`, `O`, `1`, `I`).
  static const String alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static const String qrSchemePrefix = 'creaflow://join/';

  static String generate({int length = defaultLength, Random? random}) {
    if (length <= 0) {
      throw ArgumentError.value(
        length,
        'length',
        'Panjang kode undangan harus lebih dari 0.',
      );
    }

    final rng = random ?? Random.secure();
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(alphabet[rng.nextInt(alphabet.length)]);
    }
    return buffer.toString();
  }

  static String normalize(String code) => code.trim().toUpperCase();

  /// Encodes an invite code into a QR payload (`creaflow://join/<CODE>`).
  static String toQrPayload(String code) =>
      '$qrSchemePrefix${normalize(code)}';

  /// Extracts a normalized invite code from either plain text or a QR payload.
  static String extractCode(String rawInput) {
    final trimmed = rawInput.trim();
    final lower = trimmed.toLowerCase();
    if (lower.startsWith(qrSchemePrefix)) {
      var rest = trimmed.substring(qrSchemePrefix.length);
      final queryIdx = rest.indexOf('?');
      if (queryIdx != -1) {
        rest = rest.substring(0, queryIdx);
      }
      final fragmentIdx = rest.indexOf('#');
      if (fragmentIdx != -1) {
        rest = rest.substring(0, fragmentIdx);
      }
      while (rest.endsWith('/')) {
        rest = rest.substring(0, rest.length - 1);
      }
      return normalize(rest);
    }
    return normalize(trimmed);
  }

  static bool isValidFormat(String rawInput, {int length = defaultLength}) {
    final code = extractCode(rawInput);
    if (code.length != length) return false;
    for (var i = 0; i < code.length; i++) {
      if (!alphabet.contains(code[i])) return false;
    }
    return true;
  }
}
