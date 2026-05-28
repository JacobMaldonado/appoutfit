import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'config/prod_config.dart';
import 'core/di/service_locator.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase reads credentials from google-services.json (Android)
  // and GoogleService-Info.plist (iOS) — no inline options needed.
  await Firebase.initializeApp();

  await setupServiceLocator(
    const ProdConfig(),
    firebase: FirebaseInstances(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
      storage: FirebaseStorage.instance,
    ),
  );

  runApp(const ClosetApp());
}
