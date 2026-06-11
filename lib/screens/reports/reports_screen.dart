// Reports screen with period filters, analytics charts, and exports.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/export_helper.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/report_data.dart';
import '../../providers/report_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/common/vynex_app_bar.dart';
import '../../widgets/common/vynex_button.dart';
import '../../widgets/common/vynex_card.dart';

/// Reports and analytics screen.
class ReportsScreen extends StatefulWidget {
  /// Creates the reports screen.
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime? _pendingFrom;
  DateTime? _pendingTo;
  bool _isExportingSales = false;
  bool _isExportingPurchases = false;
  bool _isExportingDebts = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadReport();
      context.read<SettingsProvider>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VynexAppBar(
        title: 'Reports',
        showSettings: true,
      ),
      body: Consumer<ReportProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.data == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          final data = provider.data;
          if (data == null) {
            return _emptyChartState('No report data available.');
          }

          final width = MediaQuery.of(context).size.width;
          final cardWidth = (width - 32 - 10) / 2;

          return RefreshIndicator(
            color: AppColors.gold,
            onRefresh: provider.loadReport,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPeriodFilter(provider),
                const SizedBox(height: 12),
                _buildPaymentMethodFilter(provider),
                const SizedBox(height: 12),
                _buildSaleTypeFilter(provider),
                const SizedBox(height: 16),
                const Text(
                  'Summary',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _buildStatCards(data, cardWidth),
                ),
                if (data.paidSalesCount > 0) ...[
                  const SizedBox(height: 16),
                  _buildInsightsStrip(data, provider),
                ],
                const SizedBox(height: 16),
                _buildDailyChart(data),
                const SizedBox(height: 16),
                _buildMonthlyChart(data),
                const SizedBox(height: 16),
                _buildTopItems(data),
                const SizedBox(height: 16),
                _buildExportSection(data),
              ],
            ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodFilter(ReportProvider provider) {
    final data = provider.data;
    return VynexCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Period',
            style: TextStyle(
              color: AppColors.midGrey,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _periodButton(
                label: 'Today',
                isActive: provider.period == ReportPeriod.today,
                onTap: () => provider.setPeriod(ReportPeriod.today),
              ),
              _periodButton(
                label: 'Last 7 Days',
                isActive: provider.period == ReportPeriod.week,
                onTap: () => provider.setPeriod(ReportPeriod.week),
              ),
              _periodButton(
                label: 'This Month',
                isActive: provider.period == ReportPeriod.month,
                onTap: () => provider.setPeriod(ReportPeriod.month),
              ),
              _periodButton(
                label: 'Custom',
                isActive: provider.period == ReportPeriod.custom,
                onTap: () => provider.setPeriod(ReportPeriod.custom),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeInOut,
            height: provider.period == ReportPeriod.custom ? null : 0,
            child: provider.period == ReportPeriod.custom
                ? Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _dateTile(
                              label: 'From',
                              date: _pendingFrom ?? provider.customFrom,
                              onTap: () => _pickDate(isFrom: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _dateTile(
                              label: 'To',
                              date: _pendingTo ?? provider.customTo,
                              onTap: () => _pickDate(isFrom: false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      VynexButton.primary(
                        label: 'Apply',
                        onPressed: () {
                          final from = _pendingFrom ?? provider.customFrom;
                          final to = _pendingTo ?? provider.customTo;
                          if (from == null || to == null) {
                            SnackBarHelper.showError(
                              context,
                              'Please select both dates.',
                            );
                            return;
                          }
                          provider.setCustomRange(from, to);
                        },
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          Text(
            'Showing: ${data?.periodLabel ?? ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.goldDark,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isActive ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.black : AppColors.gold,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _dateTile({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final text =
        date == null ? 'Select' : DateFormat('dd MMM yyyy').format(date);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.midGrey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: const TextStyle(
                color: AppColors.black,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStatCards(ReportData data, double cardWidth) {
    final currency = context.read<SettingsProvider>().currencyLabel;
    final profitPositive = data.totalProfit > 0;
    final debtColor =
        data.totalDebtBalance > 0 ? AppColors.danger : AppColors.success;
    return [
      SizedBox(
        width: cardWidth,
        child: StatCard(
          label: 'Paid Sales',
          value: '${data.paidSalesCount}',
          icon: Icons.point_of_sale_rounded,
        ),
      ),
      SizedBox(
        width: cardWidth,
        child: StatCard(
          label: 'Revenue',
          value: Formatters.formatCurrency(data.totalRevenue, currency),
          icon: Icons.payments_rounded,
        ),
      ),
      SizedBox(
        width: cardWidth,
        child: StatCard(
          label: 'Profit',
          value: Formatters.formatCurrency(data.totalProfit, currency),
          icon: Icons.trending_up_rounded,
          accentColor: profitPositive ? AppColors.success : AppColors.danger,
          valueColor: profitPositive ? AppColors.success : AppColors.danger,
        ),
      ),
      SizedBox(
        width: cardWidth,
        child: StatCard(
          label: 'Purchases',
          value: '${data.purchasesCount}',
          icon: Icons.shopping_bag_rounded,
        ),
      ),
      SizedBox(
        width: cardWidth,
        child: StatCard(
          label: 'Spent',
          value: Formatters.formatCurrency(data.totalSpent, currency),
          icon: Icons.money_off_rounded,
        ),
      ),
      SizedBox(
        width: cardWidth,
        child: StatCard(
          label: 'Debt Balance',
          value: Formatters.formatCurrency(data.totalDebtBalance, currency),
          icon: Icons.account_balance_wallet_rounded,
          accentColor: debtColor,
          valueColor: debtColor,
        ),
      ),
    ];
  }

  Widget _buildPaymentMethodFilter(ReportProvider provider) {
    return VynexCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter by Payment Method:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.midGrey,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _filterPill(
                label: 'All',
                isActive: provider.paymentMethodFilter == 'all',
                onTap: () => provider.setPaymentMethodFilter('all'),
              ),
              _filterPill(
                label: 'Cash',
                isActive: provider.paymentMethodFilter == 'cash',
                onTap: () => provider.setPaymentMethodFilter('cash'),
              ),
              _filterPill(
                label: 'M-Pesa',
                isActive: provider.paymentMethodFilter == 'mpesa',
                onTap: () => provider.setPaymentMethodFilter('mpesa'),
              ),
              _filterPill(
                label: 'Paybill/Till',
                isActive: provider.paymentMethodFilter == 'paybill',
                onTap: () => provider.setPaymentMethodFilter('paybill'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaleTypeFilter(ReportProvider provider) {
    return VynexCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sale Type Filter:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.midGrey,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _filterPill(
                label: 'All',
                isActive: provider.saleTypeFilter == 'all',
                onTap: () => provider.setSaleTypeFilter('all'),
              ),
              _filterPill(
                label: 'Products Only',
                isActive: provider.saleTypeFilter == 'product',
                onTap: () => provider.setSaleTypeFilter('product'),
              ),
              _filterPill(
                label: 'Services Only',
                isActive: provider.saleTypeFilter == 'service',
                onTap: () => provider.setSaleTypeFilter('service'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterPill({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? AppColors.black : AppColors.gold,
          ),
        ),
      ),
    );
  }

  Widget _buildInsightsStrip(ReportData data, ReportProvider provider) {
    final currency = context.read<SettingsProvider>().currencyLabel;
    final isServiceFilter = provider.saleTypeFilter == 'service';
    final bestLabel =
        isServiceFilter ? 'Most Popular Service' : 'Best Selling Item';
    final profitLabel = isServiceFilter
        ? 'Most Profitable Service'
        : 'Most Profitable Item';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _insightRow(
            icon: Icons.emoji_events_rounded,
            label: bestLabel,
            value:
                '${data.bestSellingItem ?? 'N/A'} (${data.bestSellingQty} units)',
          ),
          const Divider(color: AppColors.darkGrey, height: 20),
          _insightRow(
            icon: Icons.monetization_on_rounded,
            label: profitLabel,
            value:
                '${data.mostProfitableItem ?? 'N/A'} (${Formatters.formatCurrency(data.mostProfitableAmount, currency)})',
          ),
          const Divider(color: AppColors.darkGrey, height: 20),
          _insightRow(
            icon: Icons.analytics_rounded,
            label: 'Avg Profit Per Sale',
            value: Formatters.formatCurrency(data.avgProfitPerSale, currency),
          ),
          const Divider(color: AppColors.darkGrey, height: 20),
          _insightRow(
            icon: Icons.schedule,
            label: 'Installment Sales: ',
            value: '${data.installmentSalesCount} sales',
          ),
        ],
      ),
    );
  }

  Widget _insightRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.gold, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 1),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.midGrey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyChart(ReportData data) {
    return VynexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.show_chart_rounded,
                color: AppColors.gold,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Daily Revenue and Profit',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '(Selected period, paid sales only)',
            style: TextStyle(
              color: AppColors.midGrey,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          if (data.dailyChartData.isEmpty)
            _emptyChartState('No paid sales in this period')
          else ...[
            SizedBox(
              height: 220,
              child: RepaintBoundary(
                child: LineChart(_buildDailyLineChart(data)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(AppColors.gold),
                const SizedBox(width: 6),
                const Text(
                  'Revenue',
                  style: TextStyle(color: AppColors.midGrey, fontSize: 12),
                ),
                const SizedBox(width: 20),
                _legendDot(AppColors.success),
                const SizedBox(width: 6),
                const Text(
                  'Profit',
                  style: TextStyle(color: AppColors.midGrey, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(ReportData data) {
    final currency = context.read<SettingsProvider>().currencyLabel;
    return VynexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                color: AppColors.gold,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Monthly Overview (Last 6 Months)',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Paid sales only',
            style: TextStyle(
              color: AppColors.midGrey,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          if (data.monthlyChartData.isEmpty)
            _emptyChartState('No monthly data available.')
          else ...[
            SizedBox(
              height: 220,
              child: RepaintBoundary(
                child: BarChart(
                  _buildMonthlyBarChart(data, currency),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(AppColors.gold),
                const SizedBox(width: 6),
                const Text(
                  'Revenue',
                  style: TextStyle(color: AppColors.midGrey, fontSize: 12),
                ),
                const SizedBox(width: 16),
                _legendDot(AppColors.black),
                const SizedBox(width: 6),
                const Text(
                  'Profit',
                  style: TextStyle(color: AppColors.midGrey, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopItems(ReportData data) {
    final currency = context.read<SettingsProvider>().currencyLabel;
    return VynexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: AppColors.gold,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Top Performing Items',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '(By profit, selected period)',
            style: TextStyle(
              color: AppColors.midGrey,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          if (data.topItems.isEmpty)
            _emptyChartState('No sales data for this period.')
          else
            Column(
              children: [
                _topRow(
                  isHeader: true,
                  rank: 'Rank',
                  item: 'Item',
                  qty: 'Qty',
                  revenue: 'Revenue',
                  profit: 'Profit',
                ),
                ...List.generate(data.topItems.length, (index) {
                  final item = data.topItems[index];
                  final profit = item['total_profit'] as double;
                  final tint = index == 0
                      ? AppColors.gold.withValues(alpha: 0.15)
                      : (index.isEven ? AppColors.offWhite : AppColors.white);
                  return _topRow(
                    rank: index == 0 ? '🥇' : '${index + 1}',
                    item: item['item_name'] as String,
                    qty: '${item['total_qty']}',
                    revenue: Formatters.formatCurrency(
                      item['total_revenue'] as double,
                      currency,
                    ),
                    profit: Formatters.formatCurrency(profit, currency),
                    bgColor: tint,
                    profitColor:
                        profit < 0 ? AppColors.danger : AppColors.success,
                    boldItem: index == 0,
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  Widget _topRow({
    required String rank,
    required String item,
    required String qty,
    required String revenue,
    required String profit,
    bool isHeader = false,
    bool boldItem = false,
    Color? bgColor,
    Color? profitColor,
  }) {
    final textColor = isHeader ? AppColors.gold : AppColors.black;
    final rowBg = isHeader ? AppColors.darkGrey : (bgColor ?? AppColors.white);
    return Container(
      decoration: BoxDecoration(
        color: rowBg,
        border: const Border(
          bottom: BorderSide(color: AppColors.lightGrey),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              rank,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              item,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight:
                    boldItem || isHeader ? FontWeight.w700 : FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              qty,
              style: TextStyle(
                color: isHeader ? textColor : AppColors.midGrey,
                fontSize: 12,
                fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: Text(
              revenue,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: Text(
              profit,
              style: TextStyle(
                color: isHeader ? textColor : (profitColor ?? AppColors.black),
                fontSize: 12,
                fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportSection(ReportData data) {
    final settingsProvider = context.read<SettingsProvider>();
    final currency = settingsProvider.currencyLabel;
    return VynexCard(
      hasAccent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.file_download_rounded,
                color: AppColors.gold,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Export Data',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '(All records, not filtered by period)',
            style: TextStyle(
              color: AppColors.midGrey,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          VynexButton.primary(
            label: 'Export Sales to Excel',
            icon: Icons.table_chart_rounded,
            isLoading: _isExportingSales,
            onPressed: () async {
              setState(() => _isExportingSales = true);
              try {
                await ExportHelper.exportSales(data.allSales, currency);
              } catch (_) {
                if (mounted) {
                  SnackBarHelper.showError(
                    context,
                    'Export failed. Please try again.',
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isExportingSales = false);
                }
              }
            },
          ),
          const SizedBox(height: 10),
          VynexButton.secondary(
            label: 'Export Purchases to Excel',
            icon: Icons.shopping_bag_rounded,
            isLoading: _isExportingPurchases,
            onPressed: () async {
              setState(() => _isExportingPurchases = true);
              try {
                await ExportHelper.exportPurchases(data.allPurchases, currency);
              } catch (_) {
                if (mounted) {
                  SnackBarHelper.showError(
                    context,
                    'Export failed. Please try again.',
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isExportingPurchases = false);
                }
              }
            },
          ),
          const SizedBox(height: 10),
          VynexButton.secondary(
            label: 'Export Debts to Excel',
            icon: Icons.account_balance_wallet_rounded,
            isLoading: _isExportingDebts,
            onPressed: () async {
              setState(() => _isExportingDebts = true);
              try {
                await ExportHelper.exportDebts(currency);
              } catch (_) {
                if (mounted) {
                  SnackBarHelper.showError(
                    context,
                    'Export failed. Please try again.',
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isExportingDebts = false);
                }
              }
            },
          ),
          const SizedBox(height: 8),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.gold,
                size: 13,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Files open in Microsoft Excel, Google Sheets, and '
                  'LibreOffice Calc. Share via WhatsApp, Telegram, or email.',
                  style: TextStyle(
                    color: AppColors.midGrey,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  LineChartData _buildDailyLineChart(ReportData data) {
    if (data.dailyChartData.isEmpty) {
      return LineChartData();
    }

    final revenueSpots = <FlSpot>[];
    final profitSpots = <FlSpot>[];
    for (var i = 0; i < data.dailyChartData.length; i++) {
      final daily = data.dailyChartData[i];
      revenueSpots.add(FlSpot(i.toDouble(), daily['revenue'] as double));
      profitSpots.add(FlSpot(i.toDouble(), daily['profit'] as double));
    }

    return LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: revenueSpots,
          isCurved: true,
          color: AppColors.gold,
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.gold.withValues(alpha: 0.08),
          ),
        ),
        LineChartBarData(
          spots: profitSpots,
          isCurved: true,
          color: AppColors.success,
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.success.withValues(alpha: 0.08),
          ),
        ),
      ],
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: _calculateLabelInterval(data.dailyChartData.length),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= data.dailyChartData.length) {
                return const SizedBox.shrink();
              }
              final dateStr = data.dailyChartData[index]['date'] as String;
              final date = DateTime.parse(dateStr);
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  DateFormat('d/M').format(date),
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.midGrey,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 46,
            getTitlesWidget: (value, meta) {
              if (value == 0) {
                return const Text(
                  '0',
                  style: TextStyle(fontSize: 9, color: AppColors.midGrey),
                );
              }
              final text = value >= 1000
                  ? '${(value / 1000).toStringAsFixed(1)}K'
                  : value.toStringAsFixed(0);
              return Text(
                text,
                style: const TextStyle(fontSize: 9, color: AppColors.midGrey),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => const FlLine(
          color: AppColors.lightGrey,
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
    );
  }

  BarChartData _buildMonthlyBarChart(
    ReportData data,
    String currency,
  ) {
    if (data.monthlyChartData.isEmpty) {
      return BarChartData();
    }

    final groups = <BarChartGroupData>[];
    for (var i = 0; i < data.monthlyChartData.length; i++) {
      final month = data.monthlyChartData[i];
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: month['revenue'] as double,
              color: AppColors.gold,
              width: 10,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: month['profit'] as double,
              color: AppColors.black,
              width: 10,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return BarChartData(
      barGroups: groups,
      alignment: BarChartAlignment.spaceAround,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= data.monthlyChartData.length) {
                return const SizedBox.shrink();
              }
              final monthString =
                  data.monthlyChartData[index]['month'] as String;
              final parts = monthString.split('-');
              final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  DateFormat('MMM').format(dt),
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.midGrey,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 46,
            getTitlesWidget: (value, meta) {
              if (value == 0) {
                return const Text(
                  '0',
                  style: TextStyle(fontSize: 9, color: AppColors.midGrey),
                );
              }
              final text = value >= 1000
                  ? '${(value / 1000).toStringAsFixed(1)}K'
                  : value.toStringAsFixed(0);
              return Text(
                text,
                style: const TextStyle(fontSize: 9, color: AppColors.midGrey),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => const FlLine(
          color: AppColors.lightGrey,
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final label = rodIndex == 0 ? 'Revenue' : 'Profit';
            return BarTooltipItem(
              '$label\n$currency ${rod.toY.toStringAsFixed(0)}',
              const TextStyle(
                color: AppColors.white,
                fontSize: 11,
              ),
            );
          },
        ),
      ),
    );
  }

  double _calculateLabelInterval(int count) {
    if (count <= 7) {
      return 1;
    }
    if (count <= 14) {
      return 2;
    }
    if (count <= 21) {
      return 3;
    }
    return 5;
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _emptyChartState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bar_chart_rounded,
              color: AppColors.midGrey,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.midGrey,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final current = isFrom ? _pendingFrom : _pendingTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.gold,
              onPrimary: AppColors.black,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      if (isFrom) {
        _pendingFrom = picked;
      } else {
        _pendingTo = picked;
      }
    });
  }
}
