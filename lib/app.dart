// MaterialApp and theme setup for Vynex.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';

/// Root widget for the Vynex application.
class VynexApp extends StatelessWidget {
  /// Creates the Vynex app widget.
  const VynexApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Vynex',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: router,
    );
  }
}
