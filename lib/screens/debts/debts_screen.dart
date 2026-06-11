// Debts list screen with summary stats, tabs, and pull to refresh.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/debt_with_sale.dart';
import '../../providers/debt_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/vynex_app_bar.dart';
import '../../widgets/debts/debt_list_item.dart';

/// Debt tracker list with pending and cleared tabs.
class DebtsScreen extends StatefulWidget {
  /// Creates the debts screen.
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DebtProvider>().loadDebts();
    });
  }

  Future<void> _onRefresh() async {
    await context.read<DebtProvider>().loadDebts();
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currencyLabel;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: const VynexAppBar(
        title: 'Debt Tracker',
        showSettings: true,
      ),
      body: Consumer<DebtProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.debtsWithSale.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          return DefaultTabController(
            length: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'Pending',
                          value: '${provider.pendingCount}',
                          icon: Icons.pending_actions_rounded,
                          accentColor: provider.pendingCount > 0
                              ? AppColors.danger
                              : AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Total Owed',
                          value: Formatters.formatCurrency(
                            provider.totalOwed,
                            currency,
                          ),
                          icon: Icons.money_off_rounded,
                          accentColor: AppColors.danger,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Balance Due',
                          value: Formatters.formatCurrency(
                            provider.totalBalance,
                            currency,
                          ),
                          icon: Icons.account_balance_wallet_rounded,
                          accentColor: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  color: AppColors.white,
                  child: TabBar(
                    indicatorColor: AppColors.gold,
                    indicatorWeight: 3,
                    labelColor: AppColors.gold,
                    unselectedLabelColor: AppColors.midGrey,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 13,
                    ),
                    tabs: [
                      Tab(text: 'Pending (${provider.pendingCount})'),
                      Tab(text: 'Cleared (${provider.clearedCount})'),
                    ],
                  ),
                ),
                if (provider.pendingCount > 0)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppColors.gold,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Tip: Debts are created automatically when a '
                            'sale is recorded as not fully paid.',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: AppColors.midGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _DebtTabList(
                        items: provider.pendingDebtsWithSale,
                        isCleared: false,
                        onRefresh: _onRefresh,
                      ),
                      _DebtTabList(
                        items: provider.clearedDebtsWithSale,
                        isCleared: true,
                        onRefresh: _onRefresh,
                      ),
                    ],
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          top: BorderSide(color: accentColor, width: 3),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
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
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtTabList extends StatelessWidget {
  const _DebtTabList({
    required this.items,
    required this.isCleared,
    required this.onRefresh,
  });

  final List<DebtWithSale> items;
  final bool isCleared;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        color: AppColors.gold,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: isCleared ? 80 : 120),
            EmptyStateWidget(
              icon: isCleared
                  ? Icons.history_rounded
                  : Icons.check_circle_outline,
              title: isCleared ? 'No cleared debts yet' : 'No pending debts',
              subtitle: isCleared
                  ? 'Cleared debts will appear here'
                  : 'All your sales are fully paid. Great work!',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return DebtListItem(
            item: items[index],
            isCleared: isCleared,
          );
        },
      ),
    );
  }
}
