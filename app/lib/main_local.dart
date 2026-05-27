import 'package:flutter/material.dart';
import 'config/local_config.dart';
import 'core/di/service_locator.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator(const LocalConfig());
  runApp(const ClosetApp());
}
