// Main navigation shell with bottom navigation bar.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/customer_provider.dart';
import '../../providers/product_provider.dart';
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
      route: AppRoutes.catalog,
      label: 'Catalog',
      icon: Icons.inventory_2_rounded,
    ),
    _NavTab(
      route: AppRoutes.sales,
      label: 'Sales',
      icon: Icons.point_of_sale_rounded,
    ),
    _NavTab(
      route: AppRoutes.customers,
      label: 'Customers',
      icon: Icons.people_rounded,
    ),
    _NavTab(
      route: AppRoutes.reports,
      label: 'Reports',
      icon: Icons.bar_chart_rounded,
    ),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].route)) {
        return i;
      }
    }
    return 0;
  }

  void _onDestinationSelected(int index) {
    context.go(_tabs[index].route);
    switch (index) {
      case 0:
        break;
      case 1:
        context.read<ProductProvider>().loadProducts();
        break;
      case 2:
        context.read<SaleProvider>().loadSales();
        break;
      case 3:
        context.read<CustomerProvider>().loadCustomers();
        break;
      case 4:
        context.read<ReportProvider>().loadReport();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _currentIndex(context);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: _onDestinationSelected,
        backgroundColor: AppColors.black,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.midGrey,
        type: BottomNavigationBarType.fixed,
        items: _tabs
            .map(
              (tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavTab {
  const _NavTab({
    required this.route,
    required this.label,
    required this.icon,
  });

  final String route;
  final String label;
  final IconData icon;
}
