import 'package:firebase_auth/firebase_auth.dart';

/// Application-level authentication exception with user-friendly messages.
class AppAuthException implements Exception {
  const AppAuthException({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  factory AppAuthException.fromFirebase(FirebaseAuthException e) {
    final message = switch (e.code) {
      'email-already-in-use' => 'Email sudah terdaftar. Silakan gunakan email lain.',
      'invalid-email' => 'Format email tidak valid.',
      'weak-password' => 'Kata sandi terlalu lemah. Gunakan minimal 6 karakter.',
      'user-not-found' => 'Akun dengan email tersebut tidak ditemukan.',
      'wrong-password' => 'Kata sandi yang Anda masukkan salah.',
      'invalid-credential' => 'Email atau kata sandi tidak valid.',
      'user-disabled' => 'Akun ini telah dinonaktifkan.',
      'too-many-requests' => 'Terlalu banyak percobaan. Silakan coba lagi nanti.',
      'network-request-failed' => 'Koneksi jaringan bermasalah. Periksa internet Anda.',
      'operation-not-allowed' => 'Metode autentikasi ini tidak diizinkan.',
      _ => e.message ?? 'Terjadi kesalahan autentikasi (${e.code}).',
    };

    return AppAuthException(code: e.code, message: message);
  }

  @override
  String toString() => 'AppAuthException($code): $message';
}
