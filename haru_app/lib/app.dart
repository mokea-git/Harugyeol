import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class HarugyeolApp extends StatelessWidget {
  const HarugyeolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '하루결',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
