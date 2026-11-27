import 'package:firebase_core/firebase_core.dart';

/// Application-level exception for notifications and activity logs.
class NotificationException implements Exception {
  const NotificationException({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  factory NotificationException.fromFirebase(FirebaseException e) {
    final message = switch (e.code) {
      'permission-denied' =>
        'Anda tidak memiliki izin untuk mengakses notifikasi atau log ini.',
      'not-found' => 'Data notifikasi tidak ditemukan.',
      'unavailable' =>
        'Layanan sedang tidak tersedia. Periksa koneksi internet Anda.',
      'deadline-exceeded' => 'Permintaan melebihi batas waktu. Coba lagi.',
      'unauthenticated' => 'Silakan login terlebih dahulu.',
      _ => e.message ?? 'Terjadi kesalahan notifikasi (${e.code}).',
    };

    return NotificationException(code: e.code, message: message);
  }

  @override
  String toString() => 'NotificationException($code): $message';
}
