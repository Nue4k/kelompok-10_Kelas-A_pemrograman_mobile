import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_collections.dart';
import '../models/user_model.dart';

/// Repository for managing user profiles in Firestore (`users/{uid}`).
class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(FirestoreCollections.users);

  /// Creates a new user profile document at `users/{user.id}` with server timestamp.
  Future<void> createUser(UserModel user) async {
    final data = <String, dynamic>{
      'fullName': user.fullName.trim(),
      'email': user.email.trim().toLowerCase(),
      'profilePicture': user.profilePicture,
      'phoneNumber': user.phoneNumber,
      'createdAt': FieldValue.serverTimestamp(),
    };
    await _usersRef.doc(user.id).set(data);
  }

  /// Fetches a user profile by [uid], returning `null` if it does not exist.
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Watches a user profile in real time.
  Stream<UserModel?> watchUser(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  /// Updates allowed profile fields (`fullName`, `profilePicture`, `phoneNumber`).
  Future<void> updateProfile({
    required String uid,
    String? fullName,
    String? profilePicture,
    String? phoneNumber,
    bool clearProfilePicture = false,
    bool clearPhoneNumber = false,
  }) async {
    final updates = <String, dynamic>{};

    if (fullName != null) {
      final trimmed = fullName.trim();
      if (trimmed.isEmpty || trimmed.length > 100) {
        throw ArgumentError.value(
          fullName,
          'fullName',
          'Nama lengkap harus diisi dan maksimal 100 karakter.',
        );
      }
      updates['fullName'] = trimmed;
    }

    if (clearProfilePicture) {
      updates['profilePicture'] = null;
    } else if (profilePicture != null) {
      final trimmed = profilePicture.trim();
      updates['profilePicture'] = trimmed.isEmpty ? null : trimmed;
    }

    if (clearPhoneNumber) {
      updates['phoneNumber'] = null;
    } else if (phoneNumber != null) {
      final trimmed = phoneNumber.trim();
      updates['phoneNumber'] = trimmed.isEmpty ? null : trimmed;
    }

    if (updates.isEmpty) return;
    await _usersRef.doc(uid).update(updates);
  }
}
