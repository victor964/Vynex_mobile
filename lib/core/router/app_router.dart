// GoRouter configuration with all named routes for Vynex.

import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/catalog/add_product_screen.dart';
import '../../screens/catalog/catalog_screen.dart';
import '../../screens/catalog/edit_product_screen.dart';
import '../../screens/catalog/product_detail_screen.dart';
import '../../screens/customers/add_customer_screen.dart';
import '../../screens/customers/customer_detail_screen.dart';
import '../../screens/customers/customers_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/debts/debt_detail_screen.dart';
import '../../screens/debts/debts_screen.dart';
import '../../screens/inventory/inventory_screen.dart';
import '../../screens/inventory/stock_adjustment_screen.dart';
import '../../screens/inventory/stock_movement_screen.dart';
import '../../screens/invoices/invoice_preview_screen.dart';
import '../../screens/purchases/add_purchase_screen.dart';
import '../../screens/purchases/edit_purchase_screen.dart';
import '../../screens/purchases/purchases_screen.dart';
import '../../screens/reports/reports_screen.dart';
import '../../screens/sales/add_sale_screen.dart';
import '../../screens/sales/edit_sale_screen.dart';
import '../../screens/sales/sale_detail_screen.dart';
import '../../screens/sales/sales_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/settings/change_pin_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../widgets/common/main_shell.dart';

/// Route path constants for Vynex navigation.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
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

  static const String catalog = '/catalog';
  static const String addProduct = '/catalog/add';
  static const String editProduct = '/catalog/edit/:id';
  static const String productDetail = '/catalog/detail/:id';

  static const String inventory = '/inventory';
  static const String stockAdjustment = '/inventory/adjust/:id';
  static const String stockMovements = '/inventory/movements/:id';

  static const String customers = '/customers';
  static const String addCustomer = '/customers/add';
  static const String customerDetail = '/customers/detail/:id';

  static const String invoicePreview = '/invoice/:saleId';

  /// Builds change PIN path with optional first-launch flag.
  static String changePinPath({bool isFirstLaunch = false}) {
    if (isFirstLaunch) {
      return '$changePin?firstLaunch=true';
    }
    return changePin;
  }
}

/// Creates the app [GoRouter] with auth-aware redirects.
GoRouter createAppRouter(
  AuthProvider authProvider, {
  bool showOnboarding = false,
}) {
  return GoRouter(
    refreshListenable: authProvider,
    initialLocation: showOnboarding
        ? AppRoutes.onboarding
        : AppRoutes.splash,
    redirect: (context, state) {
      final isLoggedIn = authProvider.isLoggedIn;
      final isFirstLaunch = authProvider.isFirstLaunch;
      final location = state.matchedLocation;
      final isAuthRoute = location == AppRoutes.login ||
          location == AppRoutes.splash ||
          location == AppRoutes.onboarding;
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
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
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
            path: AppRoutes.catalog,
            name: 'catalog',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CatalogScreen(),
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
            path: AppRoutes.customers,
            name: 'customers',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CustomersScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.reports,
            name: AppRoutes.reports,
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: AppRoutes.purchases,
            name: AppRoutes.purchases,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PurchasesScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.debts,
            name: AppRoutes.debts,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DebtsScreen(),
            ),
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
        builder: (context, state) {
          final customerId = state.uri.queryParameters['customerId'];
          return AddSaleScreen(
            preselectedCustomerId: customerId != null
                ? int.tryParse(customerId)
                : null,
          );
        },
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
        path: AppRoutes.addProduct,
        name: 'addProduct',
        builder: (context, state) {
          final prefill = state.uri.queryParameters['prefill'];
          return AddProductScreen(
            prefillName: prefill != null && prefill.isNotEmpty
                ? prefill
                : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.editProduct,
        name: 'editProduct',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return EditProductScreen(productId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.productDetail,
        name: 'productDetail',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.inventory,
        name: 'inventory',
        builder: (context, state) => const InventoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.stockAdjustment,
        name: 'stockAdjustment',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final mode =
              state.uri.queryParameters['mode'] ?? 'adjust';
          return StockAdjustmentScreen(
            productId: id,
            mode: mode,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.stockMovements,
        name: 'stockMovements',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return StockMovementScreen(productId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.addCustomer,
        name: 'addCustomer',
        builder: (context, state) {
          final editId = state.uri.queryParameters['edit'];
          return AddCustomerScreen(
            editCustomerId:
                editId != null ? int.tryParse(editId) : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.customerDetail,
        name: 'customerDetail',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return CustomerDetailScreen(customerId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.invoicePreview,
        name: 'invoicePreview',
        builder: (context, state) {
          final saleId = int.parse(
            state.pathParameters['saleId']!,
          );
          final invoiceId = state.uri.queryParameters['invoiceId'];
          return InvoicePreviewScreen(
            saleId: saleId,
            existingInvoiceId:
                invoiceId != null ? int.tryParse(invoiceId) : null,
          );
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
