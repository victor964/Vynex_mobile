// Dashboard home screen with stats and recent activity.

import 'package:flutter/material.dart';
import '../../core/utils/debug_log.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/database/database_helper.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/dashboard_data.dart';
import '../../providers/auth_provider.dart';
import '../../providers/debt_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/common/vynex_card.dart';
import '../../widgets/purchases/purchase_list_item_mini.dart';
import '../../widgets/sales/sale_list_item_mini.dart';

/// Main dashboard overview screen.
class DashboardScreen extends StatefulWidget {
  /// Creates the dashboard screen.
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  /// Reloads dashboard stats and settings from the database.
  Future<void> _loadData({bool showFullScreenLoader = true}) async {
    if (!mounted) return;

    if (showFullScreenLoader) {
      setState(() => _isLoading = true);
    }

    try {
      await context.read<SettingsProvider>().loadSettings();
      if (!mounted) return;
      await context.read<DebtProvider>().loadDebts();
      if (!mounted) return;
      final data = await DatabaseHelper().getDashboardData();
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      logDebug('Dashboard load error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onLock() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Lock Vynex?',
      message: 'You will need to enter your PIN to open the app again.',
      confirmLabel: 'Yes',
      cancelLabel: 'Cancel',
    );
    if (!confirmed || !mounted) return;

    await context.read<AuthProvider>().logout();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currencyLabel;
    final businessName = settings.businessName;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.gold,
        title: Text(
          businessName,
          style: const TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.gold),
            onPressed: () => context.push(AppRoutes.settings),
          ),
          IconButton(
            icon: const Icon(
              Icons.lock_outline,
              color: AppColors.gold,
            ),
            onPressed: _onLock,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            )
          : RefreshIndicator(
              color: AppColors.gold,
              onRefresh: () => _loadData(showFullScreenLoader: false),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: _buildContent(context, currency),
              ),
            ),
    );
  }

  Widget _buildContent(BuildContext context, String currency) {
    final data = _data!;
    final pendingDebts = context.watch<DebtProvider>().pendingCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            GestureDetector(
              onTap: () => context.go(AppRoutes.purchases),
              child: StatCard(
                label: 'Purchases',
                value: '${data.totalPurchases}',
                icon: Icons.shopping_bag_rounded,
              ),
            ),
            GestureDetector(
              onTap: () => context.go(AppRoutes.sales),
              child: StatCard(
                label: 'Sales',
                value: '${data.totalSales}',
                icon: Icons.point_of_sale_rounded,
              ),
            ),
            GestureDetector(
              onTap: () => context.go(AppRoutes.reports),
              child: StatCard(
                label: 'Total Profit',
                value: Formatters.formatCurrency(
                  data.totalProfit,
                  currency,
                ),
                icon: Icons.trending_up_rounded,
                accentColor: data.totalProfit < 0
                    ? AppColors.danger
                    : data.totalProfit > 0
                        ? AppColors.success
                        : AppColors.midGrey,
                valueColor: data.totalProfit < 0
                    ? AppColors.danger
                    : data.totalProfit > 0
                        ? AppColors.success
                        : AppColors.midGrey,
              ),
            ),
            GestureDetector(
              onTap: () => context.go(AppRoutes.debts),
              child: StatCard(
                label: 'Pending Debts',
                value: '${data.pendingDebts}',
                icon: Icons.account_balance_wallet_rounded,
                accentColor: data.pendingDebts > 0
                    ? AppColors.danger
                    : AppColors.success,
              ),
            ),
          ],
        ),
        if (data.totalCatalogProducts > 0) ...[
          const SizedBox(height: 12),
          VynexCard(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_rounded,
                        color: AppColors.goldOnLight,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Inventory Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.black,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.inventory),
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: AppColors.goldOnLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _miniInventoryStat(
                        label: 'In Stock',
                        value:
                            '${data.totalCatalogProducts - data.lowStockCount - data.outOfStockCount}',
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 12),
                      _miniInventoryStat(
                        label: 'Low Stock',
                        value: '${data.lowStockCount}',
                        color: data.lowStockCount > 0
                            ? AppColors.warning
                            : AppColors.midGrey,
                      ),
                      const SizedBox(width: 12),
                      _miniInventoryStat(
                        label: 'Out of Stock',
                        value: '${data.outOfStockCount}',
                        color: data.outOfStockCount > 0
                            ? AppColors.danger
                            : AppColors.midGrey,
                      ),
                    ],
                  ),
                  if (data.outOfStockCount > 0 ||
                      data.lowStockCount > 0) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.inventory),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.warning,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.warning,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${data.outOfStockCount} out of stock, '
                              '${data.lowStockCount} low. '
                              'Tap to restock.',
                              style: const TextStyle(
                                color: AppColors.warning,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        if (data.totalCustomers > 0) ...[
          const SizedBox(height: 12),
          VynexCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.people_rounded,
                    color: AppColors.goldOnLight,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${data.totalCustomers} Customers',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.black,
                    ),
                  ),
                  if (data.customersWithDebt > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.danger,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${data.customersWithDebt} with debt',
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.customers),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: AppColors.goldOnLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                label: '+ Purchase',
                icon: Icons.add_shopping_cart,
                onTap: () async {
                  await context.push(AppRoutes.addPurchase);
                  if (context.mounted) {
                    await _loadData();
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                label: '+ Sale',
                icon: Icons.add_circle_outline,
                onTap: () => context.push(AppRoutes.addSale),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MoreActionButton(
                label: 'Purchases',
                onTap: () => context.go(AppRoutes.purchases),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MoreActionButton(
                label: 'Debts',
                badgeCount: pendingDebts,
                onTap: () => context.go(AppRoutes.debts),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.inventory),
                icon: const Icon(
                  Icons.inventory_2_rounded,
                  color: AppColors.goldOnLight,
                  size: 16,
                ),
                label: const Text(
                  'Inventory',
                  style: TextStyle(
                    color: AppColors.goldOnLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: AppColors.gold,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        VynexCard(
          hasAccent: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    color: AppColors.goldOnLight,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'This Month',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _MonthRow(
                label: 'Revenue',
                value: Formatters.formatCurrency(
                  data.monthRevenue,
                  currency,
                ),
                valueColor: data.monthRevenue > 0
                    ? AppColors.goldOnLight
                    : AppColors.midGrey,
                showDivider: true,
              ),
              _MonthRow(
                label: 'Profit',
                value: Formatters.formatCurrency(
                  data.monthProfit,
                  currency,
                ),
                valueColor: data.monthProfit >= 0
                    ? AppColors.success
                    : AppColors.danger,
                showDivider: true,
              ),
              _MonthRow(
                label: 'Spent',
                value: Formatters.formatCurrency(
                  data.monthSpent,
                  currency,
                ),
                valueColor: AppColors.darkGrey,
                showDivider: false,
              ),
              if (data.pendingDebts > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 13,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${data.pendingDebts} unpaid sale(s) not '
                          'included in profit and revenue totals.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.warning,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _SectionHeader(
          title: 'Recent Sales',
          onViewAll: () => context.go(AppRoutes.sales),
        ),
        const SizedBox(height: 8),
        if (data.recentSales.isEmpty)
          const _CompactEmpty(message: 'No sales yet')
        else
          ...data.recentSales.map(
            (s) => SaleListItemMini(sale: s),
          ),
        const SizedBox(height: 24),
        _SectionHeader(
          title: 'Recent Purchases',
          onViewAll: () => context.go(AppRoutes.purchases),
        ),
        const SizedBox(height: 8),
        if (data.recentPurchases.isEmpty)
          const _CompactEmpty(message: 'No purchases yet')
        else
          ...data.recentPurchases.map(
            (p) => PurchaseListItemMini(purchase: p),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

Widget _miniInventoryStat({
  required String label,
  required String value,
  required Color color,
}) {
  return Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.midGrey,
          ),
        ),
      ],
    ),
  );
}

class _MoreActionButton extends StatelessWidget {
  const _MoreActionButton({
    required this.label,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String label;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.goldOnLight,
          side: const BorderSide(color: AppColors.gold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        child: badgeCount > 0
            ? Badge(
                isLabelVisible: true,
                label: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: const TextStyle(fontSize: 9),
                ),
                backgroundColor: AppColors.danger,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.goldOnLight,
                  ),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.goldOnLight,
                ),
              ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.showDivider,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.onViewAll,
  });

  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.black,
            fontSize: 16,
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          child: const Text(
            'View All',
            style: TextStyle(
              color: AppColors.goldOnLight,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactEmpty extends StatelessWidget {
  const _CompactEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.midGrey,
              ),
        ),
      ),
    );
  }
}
