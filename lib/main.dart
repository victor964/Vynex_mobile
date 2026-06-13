// Entry point for Vynex app.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/database/database_helper.dart';
import 'core/router/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/category_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/debt_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/product_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/report_provider.dart';
import 'providers/sale_provider.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = DatabaseHelper();
  await db.database;

  final prefs = await SharedPreferences.getInstance();
  var hasCompletedOnboarding =
      prefs.getBool('onboarding_complete') ?? false;

  if (!hasCompletedOnboarding) {
    final hasData = await db.hasExistingUserData();
    if (hasData) {
      await prefs.setBool('onboarding_complete', true);
      hasCompletedOnboarding = true;
    }
  }

  final authProvider = AuthProvider();
  await authProvider.checkSession();

  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();

  final router = createAppRouter(
    authProvider,
    showOnboarding: !hasCompletedOnboarding,
  );

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
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
      ],
      child: VynexApp(
        router: router,
        showOnboarding: !hasCompletedOnboarding,
      ),
    ),
  );
}
