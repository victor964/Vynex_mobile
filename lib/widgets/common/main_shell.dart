// Main navigation shell with bottom navigation bar.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/debt_provider.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/sale_provider.dart';

/// Wraps main tab screens with a persistent bottom navigation bar.
class MainShell extends StatefulWidget {
  /// Creates the main navigation shell.
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _tabs = [
    _NavTab(
      route: AppRoutes.dashboard,
      label: 'Dashboard',
      icon: Icons.dashboard_rounded,
    ),
    _NavTab(
      route: AppRoutes.purchases,
      label: 'Purchases',
      icon: Icons.shopping_bag_rounded,
    ),
    _NavTab(
      route: AppRoutes.sales,
      label: 'Sales',
      icon: Icons.point_of_sale_rounded,
    ),
    _NavTab(
      route: AppRoutes.debts,
      label: 'Debts',
      icon: Icons.account_balance_wallet_rounded,
      isDebtsTab: true,
    ),
    _NavTab(
      route: AppRoutes.reports,
      label: 'Reports',
      icon: Icons.bar_chart_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DebtProvider>().loadDebts();
    });
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].route)) {
        return i;
      }
    }
    return 0;
  }

  void _onTap(int index) {
    context.go(_tabs[index].route);
    if (index == 1) {
      context.read<PurchaseProvider>().loadPurchases();
    }
    if (index == 2) {
      context.read<SaleProvider>().loadSales();
    }
    if (index == 4) {
      context.read<ReportProvider>().loadReport();
    }
    context.read<DebtProvider>().loadDebts();
  }

  Widget _buildIcon(_NavTab tab, int pendingCount) {
    if (tab.isDebtsTab) {
      return Badge(
        isLabelVisible: pendingCount > 0,
        label: Text(
          pendingCount > 9 ? '9+' : '$pendingCount',
          style: const TextStyle(fontSize: 10),
        ),
        backgroundColor: AppColors.danger,
        child: Icon(tab.icon),
      );
    }
    return Icon(tab.icon);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _currentIndex(context);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Consumer<DebtProvider>(
        builder: (context, debtProvider, _) {
          return BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: _onTap,
            backgroundColor: AppColors.black,
            selectedItemColor: AppColors.gold,
            unselectedItemColor: AppColors.midGrey,
            type: BottomNavigationBarType.fixed,
            items: _tabs
                .map(
                  (tab) => BottomNavigationBarItem(
                    icon: _buildIcon(tab, debtProvider.pendingCount),
                    label: tab.label,
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class _NavTab {
  const _NavTab({
    required this.route,
    required this.label,
    required this.icon,
    this.isDebtsTab = false,
  });

  final String route;
  final String label;
  final IconData icon;
  final bool isDebtsTab;
}
