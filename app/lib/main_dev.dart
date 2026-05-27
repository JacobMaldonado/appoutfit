import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'config/dev_config.dart';
import 'core/di/service_locator.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const config = DevConfig();
  final opts = config.firebaseOptions;

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: opts.apiKey,
      appId: opts.appId,
      messagingSenderId: opts.messagingSenderId,
      projectId: opts.projectId,
      storageBucket: opts.storageBucket,
    ),
  );

  await setupServiceLocator(
    config,
    firebase: FirebaseInstances(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
      storage: FirebaseStorage.instance,
    ),
  );

  runApp(const ClosetApp());
}
