import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import 'app.dart';
import 'services/local_store.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStore.instance.init();
  pdfrxFlutterInitialize();
  try {
    await NotificationService.instance.init();
  } catch (_) {
    // Notifications are optional; ignore setup failures.
  }
  runApp(const ShibirSyllabusApp());
}
