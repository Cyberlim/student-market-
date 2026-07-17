import 'package:flutter/material.dart';
import 'core/router/router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
