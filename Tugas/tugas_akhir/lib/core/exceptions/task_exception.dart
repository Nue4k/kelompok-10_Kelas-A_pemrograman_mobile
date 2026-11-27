import 'package:firebase_core/firebase_core.dart';

/// Application-level task exception with user-friendly messages.
class TaskException implements Exception {
  const TaskException({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  factory TaskException.fromFirebase(FirebaseException e) {
    final message = switch (e.code) {
      'permission-denied' =>
        'Anda tidak memiliki izin untuk melakukan tindakan pada tugas ini.',
      'not-found' => 'Data tugas tidak ditemukan.',
      'already-exists' => 'Data tugas sudah ada.',
      'unavailable' =>
        'Layanan sedang tidak tersedia. Periksa koneksi internet Anda.',
      'deadline-exceeded' => 'Permintaan melebihi batas waktu. Coba lagi.',
      'unauthenticated' => 'Silakan login terlebih dahulu.',
      _ => e.message ?? 'Terjadi kesalahan tugas (${e.code}).',
    };

    return TaskException(code: e.code, message: message);
  }

  @override
  String toString() => 'TaskException($code): $message';
}
