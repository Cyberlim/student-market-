import 'package:flutter/material.dart';
import 'core/router/router.dart';
import 'core/theme/app_theme.dart';

void main() {
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
