import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:creaflow/data/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UserModel fromMap and toMap round-trip', () {
    final createdAt = DateTime(2026, 11, 26, 12, 0);
    final user = UserModel(
      id: 'uid-1',
      fullName: 'Akhmad Zaki',
      email: 'zaki@example.com',
      profilePicture: 'https://example.com/avatar.png',
      phoneNumber: '08123456789',
      createdAt: createdAt,
    );

    final map = user.toMap();
    expect(map['createdAt'], isA<Timestamp>());
    expect(map.containsKey('id'), isFalse);

    final restored = UserModel.fromMap('uid-1', map);
    expect(restored.id, 'uid-1');
    expect(restored.fullName, 'Akhmad Zaki');
    expect(restored.email, 'zaki@example.com');
    expect(restored.profilePicture, 'https://example.com/avatar.png');
    expect(restored.phoneNumber, '08123456789');
    expect(restored.createdAt, createdAt);
  });

  test('UserModel copyWith updates fields and clears nullable fields', () {
    const user = UserModel(
      id: 'uid-1',
      fullName: 'Akhmad Zaki',
      email: 'zaki@example.com',
      profilePicture: 'https://example.com/avatar.png',
      phoneNumber: '08123456789',
    );

    final updated = user.copyWith(
      fullName: 'Zaki Baru',
      clearProfilePicture: true,
      clearPhoneNumber: true,
    );

    expect(updated.id, 'uid-1');
    expect(updated.fullName, 'Zaki Baru');
    expect(updated.email, 'zaki@example.com');
    expect(updated.profilePicture, isNull);
    expect(updated.phoneNumber, isNull);
  });
}
