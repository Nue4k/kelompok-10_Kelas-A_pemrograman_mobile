import 'package:firebase_core/firebase_core.dart';

/// Application-level workspace and membership exception with user-friendly messages.
class WorkspaceException implements Exception {
  const WorkspaceException({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  factory WorkspaceException.fromFirebase(FirebaseException e) {
    final message = switch (e.code) {
      'permission-denied' =>
        'Anda tidak memiliki izin untuk melakukan tindakan ini.',
      'not-found' => 'Data workspace atau anggota tidak ditemukan.',
      'already-exists' => 'Data sudah ada.',
      'unavailable' =>
        'Layanan sedang tidak tersedia. Periksa koneksi internet Anda.',
      'deadline-exceeded' => 'Permintaan melebihi batas waktu. Coba lagi.',
      'unauthenticated' => 'Silakan login terlebih dahulu.',
      _ => e.message ?? 'Terjadi kesalahan workspace (${e.code}).',
    };

    return WorkspaceException(code: e.code, message: message);
  }

  @override
  String toString() => 'WorkspaceException($code): $message';
}
