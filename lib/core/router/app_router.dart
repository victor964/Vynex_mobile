// GoRouter configuration with all named routes for Vynex.

import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/debts/debt_detail_screen.dart';
import '../../screens/debts/debts_screen.dart';
import '../../screens/purchases/add_purchase_screen.dart';
import '../../screens/purchases/edit_purchase_screen.dart';
import '../../screens/purchases/purchases_screen.dart';
import '../../screens/reports/reports_screen.dart';
import '../../screens/sales/add_sale_screen.dart';
import '../../screens/sales/edit_sale_screen.dart';
import '../../screens/sales/sale_detail_screen.dart';
import '../../screens/sales/sales_screen.dart';
import '../../screens/settings/change_pin_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../widgets/common/main_shell.dart';

/// Route path constants for Vynex navigation.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String purchases = '/purchases';
  static const String addPurchase = '/purchases/add';
  static const String editPurchase = '/purchases/edit/:id';
  static const String sales = '/sales';
  static const String addSale = '/sales/add';
  static const String editSale = '/sales/edit/:id';
  static const String saleDetail = '/sales/detail/:id';
  static const String debts = '/debts';
  static const String debtDetail = '/debt/detail/:id';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String changePin = '/settings/pin';

  /// Builds change PIN path with optional first-launch flag.
  static String changePinPath({bool isFirstLaunch = false}) {
    if (isFirstLaunch) {
      return '$changePin?firstLaunch=true';
    }
    return changePin;
  }
}

/// Creates the app [GoRouter] with auth-aware redirects.
GoRouter createAppRouter(AuthProvider authProvider) {
  return GoRouter(
    refreshListenable: authProvider,
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isLoggedIn = authProvider.isLoggedIn;
      final isFirstLaunch = authProvider.isFirstLaunch;
      final location = state.matchedLocation;
      final isAuthRoute =
          location == AppRoutes.login || location == AppRoutes.splash;
      final isChangePin = location == AppRoutes.changePin;

      if (!isLoggedIn && !isAuthRoute) {
        return AppRoutes.login;
      }
      if (isLoggedIn && isFirstLaunch && !isChangePin) {
        return AppRoutes.changePinPath(isFirstLaunch: true);
      }
      if (isLoggedIn && location == AppRoutes.login) {
        return isFirstLaunch
            ? AppRoutes.changePinPath(isFirstLaunch: true)
            : AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: AppRoutes.dashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.purchases,
            name: AppRoutes.purchases,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PurchasesScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.sales,
            name: AppRoutes.sales,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SalesScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.debts,
            name: AppRoutes.debts,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DebtsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.reports,
            name: AppRoutes.reports,
            builder: (context, state) => const ReportsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.addPurchase,
        name: AppRoutes.addPurchase,
        builder: (context, state) => const AddPurchaseScreen(),
      ),
      GoRoute(
        path: AppRoutes.editPurchase,
        name: AppRoutes.editPurchase,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return EditPurchaseScreen(purchaseId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.addSale,
        name: AppRoutes.addSale,
        builder: (context, state) => const AddSaleScreen(),
      ),
      GoRoute(
        path: AppRoutes.editSale,
        name: AppRoutes.editSale,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return EditSaleScreen(saleId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.saleDetail,
        name: AppRoutes.saleDetail,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return SaleDetailScreen(saleId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.debtDetail,
        name: AppRoutes.debtDetail,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return DebtDetailScreen(debtId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.changePin,
        name: AppRoutes.changePin,
        builder: (context, state) {
          final isFirstLaunch =
              state.uri.queryParameters['firstLaunch'] == 'true';
          return ChangePinScreen(isFirstLaunch: isFirstLaunch);
        },
      ),
    ],
  );
}
