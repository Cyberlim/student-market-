import 'package:flutter/material.dart';
import 'core/router/router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  await AdminNotificationService.instance.initialize();
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EduMarket Admin Console',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.dark,
      routerConfig: router,
    );
  }
}
