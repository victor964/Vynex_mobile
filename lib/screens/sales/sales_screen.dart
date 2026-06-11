// Sales list screen with summary stats, empty state, and pull to refresh.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/sale_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/vynex_app_bar.dart';
import '../../widgets/common/vynex_card.dart';
import '../../widgets/sales/sale_list_item.dart';

/// Sales list screen and module entry point.
class SalesScreen extends StatefulWidget {
  /// Creates the sales screen.
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().loadSales();
      context.read<SettingsProvider>().loadSettings();
    });
  }

  Future<void> _onRefresh() async {
    await context.read<SaleProvider>().loadSales();
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currencyLabel;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: VynexAppBar(
        title: 'Sales',
        showSettings: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.gold),
            onPressed: () => context.push(AppRoutes.addSale),
          ),
        ],
      ),
      body: Consumer<SaleProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.sales.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          if (provider.sales.isEmpty) {
            return RefreshIndicator(
              color: AppColors.gold,
              onRefresh: _onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  EmptyStateWidget(
                    icon: Icons.point_of_sale_outlined,
                    title: 'No sales recorded',
                    subtitle: 'Tap the + button to record your first sale',
                  ),
                ],
              ),
            );
          }

          final profitColor = provider.totalProfit > 0
              ? AppColors.success
              : provider.totalProfit < 0
                  ? AppColors.danger
                  : AppColors.midGrey;

          return RefreshIndicator(
            color: AppColors.gold,
            onRefresh: _onRefresh,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _MiniStatCard(
                          label: 'Sales',
                          value: '${provider.salesCount}',
                          accentColor: AppColors.gold,
                          valueColor: AppColors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MiniStatCard(
                          label: 'Revenue',
                          value: Formatters.formatCurrency(
                            provider.totalRevenue,
                            currency,
                          ),
                          accentColor: AppColors.gold,
                          valueColor: AppColors.gold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MiniStatCard(
                          label: 'Profit',
                          value: Formatters.formatCurrency(
                            provider.totalProfit,
                            currency,
                          ),
                          accentColor: profitColor,
                          valueColor: profitColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: provider.sales.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final sale = provider.sales[index];
                      final debt = sale.id != null
                          ? provider.debtsBySaleId[sale.id]
                          : null;
                      return SaleListItem(
                        sale: sale,
                        debt: debt,
                        paidByInstallments: sale.id != null &&
                            provider.wasPaidByInstallments(sale.id!),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.accentColor,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color accentColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return VynexCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.midGrey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 3,
            width: 24,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
