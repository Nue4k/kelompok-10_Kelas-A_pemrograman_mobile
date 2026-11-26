import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/firestore_converters.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.profilePicture,
    this.phoneNumber,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String email;
  final String? profilePicture;
  final String? phoneNumber;
  final DateTime? createdAt;

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      profilePicture: map['profilePicture'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      createdAt: dateFromFirestore(map['createdAt']),
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return UserModel.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'profilePicture': profilePicture,
      'phoneNumber': phoneNumber,
      'createdAt': dateToFirestore(createdAt),
    };
  }
}
