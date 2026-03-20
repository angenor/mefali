import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/notification/deep_link_handler.dart';
import 'features/notification/push_notification_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init — gracefully skipped if config files missing
  try {
    await Firebase.initializeApp();
    PushNotificationHandler.instance.initialize();
  } catch (e) {
    debugPrint('Firebase init skipped (config missing): $e');
  }

  // Deep link handler for SMS fallback
  await DeepLinkHandler.instance.initialize();

  runApp(const ProviderScope(child: MefaliLivreurApp()));
}
