import 'package:creaflow/data/models/user_model.dart';
import 'package:creaflow/data/repositories/user_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late UserRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = UserRepository(firestore: firestore);
  });

  group('UserRepository', () {
    test('createUser and getUserById round-trip', () async {
      const user = UserModel(
        id: 'u1',
        fullName: '  Budi Santoso  ',
        email: '  BUDI@Example.COM ',
        profilePicture: 'https://example.com/avatar.png',
        phoneNumber: '08123456789',
      );

      await repository.createUser(user);

      final fetched = await repository.getUserById('u1');
      expect(fetched, isNotNull);
      expect(fetched!.id, 'u1');
      expect(fetched.fullName, 'Budi Santoso');
      expect(fetched.email, 'budi@example.com');
      expect(fetched.profilePicture, 'https://example.com/avatar.png');
      expect(fetched.phoneNumber, '08123456789');

      expect(await repository.getUserById('missing'), isNull);
    });

    test('watchUser emits updates', () async {
      await repository.createUser(
        const UserModel(
          id: 'u1',
          fullName: 'Ani',
          email: 'ani@example.com',
        ),
      );

      final stream = repository.watchUser('u1');
      final first = await stream.first;
      expect(first?.fullName, 'Ani');
    });

    test('updateProfile updates fields, clears nullable fields, and validates',
        () async {
      await repository.createUser(
        const UserModel(
          id: 'u1',
          fullName: 'Ani',
          email: 'ani@example.com',
          profilePicture: 'https://example.com/a.png',
          phoneNumber: '08111',
        ),
      );

      await repository.updateProfile(
        uid: 'u1',
        fullName: 'Ani Wijaya',
        clearProfilePicture: true,
        clearPhoneNumber: true,
      );

      final updated = await repository.getUserById('u1');
      expect(updated!.fullName, 'Ani Wijaya');
      expect(updated.profilePicture, isNull);
      expect(updated.phoneNumber, isNull);

      expect(
        () => repository.updateProfile(uid: 'u1', fullName: '   '),
        throwsArgumentError,
      );
    });
  });
}
