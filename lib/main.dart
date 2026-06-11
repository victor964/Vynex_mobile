// Entry point for Vynex app.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/database/database_helper.dart';
import 'core/router/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/debt_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/report_provider.dart';
import 'providers/sale_provider.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = DatabaseHelper();
  await db.database;

  final authProvider = AuthProvider();
  await authProvider.checkSession();

  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();

  final router = createAppRouter(authProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
        ),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ChangeNotifierProvider(create: (_) => SaleProvider()),
        ChangeNotifierProvider(create: (_) => DebtProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: VynexApp(router: router),
    ),
  );
}
