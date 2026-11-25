import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

const bool kUseEmulator = bool.fromEnvironment('USE_EMULATOR');

Future<void> initFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kUseEmulator) {
    final host =
        (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
            ? '10.0.2.2'
            : 'localhost';
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  }
}
