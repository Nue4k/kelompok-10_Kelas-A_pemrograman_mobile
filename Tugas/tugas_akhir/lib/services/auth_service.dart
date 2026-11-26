import 'package:firebase_auth/firebase_auth.dart';

import '../core/exceptions/auth_exception.dart';
import '../data/models/user_model.dart';
import '../data/repositories/user_repository.dart';

/// Service for Firebase Authentication and user profile coordination.
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    UserRepository? userRepository,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _userRepository = userRepository ?? UserRepository();

  final FirebaseAuth _auth;
  final UserRepository _userRepository;

  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  static void validateRegisterInput({
    required String fullName,
    required String email,
    required String password,
  }) {
    final trimmedName = fullName.trim();
    if (trimmedName.isEmpty || trimmedName.length > 100) {
      throw const AppAuthException(
        code: 'invalid-full-name',
        message: 'Nama lengkap harus diisi dan maksimal 100 karakter.',
      );
    }

    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      throw const AppAuthException(
        code: 'invalid-email',
        message: 'Format email tidak valid.',
      );
    }

    if (password.length < 6) {
      throw const AppAuthException(
        code: 'weak-password',
        message: 'Kata sandi minimal 6 karakter.',
      );
    }
  }

  static void validateLoginInput({
    required String email,
    required String password,
  }) {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      throw const AppAuthException(
        code: 'invalid-email',
        message: 'Format email tidak valid.',
      );
    }

    if (password.isEmpty) {
      throw const AppAuthException(
        code: 'empty-password',
        message: 'Kata sandi tidak boleh kosong.',
      );
    }
  }

  /// Registers a new user in Firebase Auth and creates their Firestore profile.
  /// Rolls back the Firebase Auth user if Firestore profile creation fails.
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    validateRegisterInput(
      fullName: fullName,
      email: email,
      password: password,
    );

    final trimmedName = fullName.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final trimmedPhone = phoneNumber?.trim();

    final UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AppAuthException.fromFirebase(e);
    }

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw const AppAuthException(
        code: 'user-creation-failed',
        message: 'Gagal membuat akun pengguna.',
      );
    }

    final userModel = UserModel(
      id: firebaseUser.uid,
      fullName: trimmedName,
      email: firebaseUser.email ?? normalizedEmail,
      phoneNumber: (trimmedPhone == null || trimmedPhone.isEmpty)
          ? null
          : trimmedPhone,
    );

    try {
      await firebaseUser.updateDisplayName(trimmedName);
      await _userRepository.createUser(userModel);
      return userModel;
    } on FirebaseAuthException catch (e) {
      try {
        await firebaseUser.delete();
      } catch (_) {}
      throw AppAuthException.fromFirebase(e);
    } catch (_) {
      try {
        await firebaseUser.delete();
      } catch (_) {}
      rethrow;
    }
  }

  /// Signs in with email and password and returns the Firestore [UserModel].
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    validateLoginInput(email: email, password: password);

    final normalizedEmail = email.trim().toLowerCase();
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) return null;
      return await _userRepository.getUserById(uid);
    } on FirebaseAuthException catch (e) {
      throw AppAuthException.fromFirebase(e);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final uid = currentUid;
    if (uid == null) return null;
    return _userRepository.getUserById(uid);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      throw const AppAuthException(
        code: 'invalid-email',
        message: 'Format email tidak valid.',
      );
    }

    try {
      await _auth.sendPasswordResetEmail(email: trimmedEmail);
    } on FirebaseAuthException catch (e) {
      throw AppAuthException.fromFirebase(e);
    }
  }
}
