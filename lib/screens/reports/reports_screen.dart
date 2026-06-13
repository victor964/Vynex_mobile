// Reports screen with period filters, analytics charts, and exports.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/database/database_helper.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/export_helper.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/product.dart';
import '../../models/report_data.dart';
import '../../providers/report_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/catalog/stock_badge_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/stat_card.dart';
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
  bool _exportingInventory = false;
  bool _exportingCustomers = false;

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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Reports',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.gold,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_rounded),
              color: AppColors.gold,
              tooltip: 'Settings',
              onPressed: () => context.push(AppRoutes.settings),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.gold,
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.midGrey,
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            tabs: [
              Tab(text: 'Sales'),
              Tab(text: 'Inventory'),
              Tab(text: 'Customers'),
            ],
          ),
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

            return TabBarView(
              children: [
                _buildSalesReportTab(data, provider),
                _buildInventoryReportTab(data, provider),
                _buildCustomerReportTab(data, provider),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _exportSales(ReportData data) async {
    setState(() => _isExportingSales = true);
    try {
      final settings = context.read<SettingsProvider>();
      await ExportHelper.exportSales(
        data.allSales,
        settings.currencyLabel,
        businessName: settings.businessName,
      );
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
  }

  Future<void> _exportPurchases(ReportData data) async {
    setState(() => _isExportingPurchases = true);
    try {
      await ExportHelper.exportPurchases(
        data.allPurchases,
        context.read<SettingsProvider>().currencyLabel,
      );
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
  }

  Future<void> _exportDebts() async {
    setState(() => _isExportingDebts = true);
    try {
      await ExportHelper.exportDebts(
        context.read<SettingsProvider>().currencyLabel,
      );
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
  }

  Future<void> _exportInventoryReport() async {
    setState(() => _exportingInventory = true);
    final settings = context.read<SettingsProvider>();
    try {
      final db = DatabaseHelper();
      final products = await db.getProducts();
      if (!mounted) {
        return;
      }
      await ExportHelper.exportInventory(
        products: products,
        currencyLabel: settings.currencyLabel,
        businessName: settings.businessName,
      );
    } catch (_) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Export failed. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _exportingInventory = false);
      }
    }
  }

  Future<void> _exportCustomerReport() async {
    setState(() => _exportingCustomers = true);
    final settings = context.read<SettingsProvider>();
    final data = context.read<ReportProvider>().data;
    try {
      if (data == null) {
        return;
      }
      await ExportHelper.exportCustomers(
        topCustomers: data.customerData.topCustomers,
        debtCustomers: data.customerData.customersWithActiveDebt,
        currencyLabel: settings.currencyLabel,
        businessName: settings.businessName,
      );
    } catch (_) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Export failed. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _exportingCustomers = false);
      }
    }
  }

  Widget _buildSalesReportTab(ReportData data, ReportProvider provider) {
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
            const SizedBox(height: 12),
            _buildSaleSourceFilter(provider),
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
            _buildSourceBreakdownChart(data),
            const SizedBox(height: 16),
            _buildTopItems(data),
            const SizedBox(height: 16),
            _buildExportSection(
              data,
              isExportingSales: _isExportingSales,
              isExportingPurchases: _isExportingPurchases,
              isExportingDebts: _isExportingDebts,
              onExportSales: () => _exportSales(data),
              onExportPurchases: () => _exportPurchases(data),
              onExportDebts: _exportDebts,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryReportTab(
    ReportData data,
    ReportProvider provider,
  ) {
    final currency = context.read<SettingsProvider>().currencyLabel;
    final inventory = data.inventoryData;
    final width = MediaQuery.of(context).size.width;
    final cardWidth = (width - 32 - 10) / 2;
    final profitPositive = inventory.potentialProfit > 0;

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: provider.loadReport,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    label: 'Total Products',
                    value: '${inventory.totalProducts}',
                    icon: Icons.inventory_2_rounded,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    label: 'Stock Value (Cost)',
                    value: Formatters.formatCurrency(
                      inventory.totalStockValueAtCost,
                      currency,
                    ),
                    icon: Icons.paid_rounded,
                    subtitle: 'at purchase price',
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    label: 'Retail Value',
                    value: Formatters.formatCurrency(
                      inventory.totalStockValueAtRetail,
                      currency,
                    ),
                    icon: Icons.storefront_rounded,
                    subtitle: 'at selling price',
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    label: 'Potential Profit',
                    value: Formatters.formatCurrency(
                      inventory.potentialProfit,
                      currency,
                    ),
                    icon: Icons.trending_up_rounded,
                    accentColor: profitPositive
                        ? AppColors.success
                        : AppColors.danger,
                    valueColor: profitPositive
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  'In Stock: ${inventory.inStockCount}',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Low Stock: ${inventory.lowStockCount}',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Out of Stock: ${inventory.outOfStockCount}',
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildLowStockSection(inventory),
            const SizedBox(height: 20),
            _buildDeadStockSection(inventory, currency),
            const SizedBox(height: 20),
            _buildTopMovingSection(inventory, currency),
            const SizedBox(height: 20),
            VynexButton.secondary(
              label: 'Export Inventory to Excel',
              icon: Icons.table_chart_outlined,
              isLoading: _exportingInventory,
              onPressed: _exportInventoryReport,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockSection(InventoryReportData inventory) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 18,
            ),
            const SizedBox(width: 8),
            const Text(
              'Items Needing Restock',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.black,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${inventory.lowStockCount}',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (inventory.lowStockItems.isEmpty)
          const Text(
            'All products are well stocked.',
            style: TextStyle(
              color: AppColors.midGrey,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          )
        else ...[
          ...inventory.lowStockItems.map(_buildLowStockRow),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.push(AppRoutes.inventory),
            child: const Text(
              'View All in Inventory',
              style: TextStyle(color: AppColors.gold),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLowStockRow(LowStockItem item) {
    final product = Product(
      id: item.productId,
      name: item.productName,
      currentStock: item.currentStock,
      lowStockThreshold: item.threshold,
      unit: item.unit,
      dateAdded: '',
      lastUpdated: '',
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: VynexCard(
        child: Container(
          color: AppColors.warning.withValues(alpha: 0.06),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  StockBadgeWidget(product: product),
                ],
              ),
              if (item.currentStock > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Only ${item.currentStock} ${item.unit}s left. '
                    'Alert threshold: ${item.threshold}',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'OUT OF STOCK',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    side: const BorderSide(color: AppColors.gold),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => context.push(
                    '/inventory/adjust/${item.productId}?mode=add',
                  ),
                  child: const Text(
                    'Restock',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeadStockSection(
    InventoryReportData inventory,
    String currency,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.hourglass_top_rounded,
              color: AppColors.gold,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Slow Moving Stock',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Products with no sales in 30 days',
          style: TextStyle(
            color: AppColors.midGrey,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        if (inventory.deadStockItems.isEmpty)
          const Text(
            'No dead stock. All products are selling well.',
            style: TextStyle(color: AppColors.midGrey, fontSize: 12),
          )
        else ...[
          _deadStockTable(inventory.deadStockItems, currency),
          const SizedBox(height: 8),
          const Text(
            'Consider running a promotion to clear slow stock '
            'and recover your investment.',
            style: TextStyle(
              color: AppColors.midGrey,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _deadStockTable(
    List<DeadStockItem> items,
    String currency,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          color: AppColors.darkGrey,
          child: const Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Product',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Stock',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Value',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Last Sold',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) {
          final lastDate = item.lastSaleDate == 'Never sold'
              ? 'Never sold'
              : Formatters.formatDate(item.lastSaleDate);
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.lightGrey),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    item.productName,
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    '${item.currentStock}',
                    style: const TextStyle(fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    Formatters.formatCurrency(item.stockValue, currency),
                    style: const TextStyle(fontSize: 11),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    lastDate,
                    style: const TextStyle(fontSize: 10),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTopMovingSection(
    InventoryReportData inventory,
    String currency,
  ) {
    final hasSales = inventory.topMovingItems.any(
      (item) => item.totalUnitsSold > 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.warning,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Top Moving Products',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          '(by units sold via catalog)',
          style: TextStyle(
            color: AppColors.midGrey,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 12),
        if (!hasSales)
          const Text(
            'No catalog sales recorded yet.',
            style: TextStyle(color: AppColors.midGrey, fontSize: 12),
          )
        else
          ...List.generate(inventory.topMovingItems.length, (index) {
            final item = inventory.topMovingItems[index];
            if (item.totalUnitsSold == 0) {
              return const SizedBox.shrink();
            }
            final isFirst = index == 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isFirst
                    ? AppColors.gold.withValues(alpha: 0.12)
                    : AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.lightGrey),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${item.totalUnitsSold} units sold',
                          style: const TextStyle(
                            color: AppColors.midGrey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Formatters.formatCurrency(
                      item.totalRevenue,
                      currency,
                    ),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCustomerReportTab(
    ReportData data,
    ReportProvider provider,
  ) {
    final currency = context.read<SettingsProvider>().currencyLabel;
    final customers = data.customerData;
    final width = MediaQuery.of(context).size.width;
    final cardWidth = (width - 32 - 10) / 2;
    final hasDebt = customers.customersWithDebt > 0;
    final debtPositive = customers.totalOutstandingDebt > 0;

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: provider.loadReport,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    label: 'Total Customers',
                    value: '${customers.totalCustomers}',
                    icon: Icons.people_rounded,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    label: 'New This Period',
                    value: '${customers.newCustomersThisPeriod}',
                    icon: Icons.person_add_rounded,
                    subtitle: 'joined in selected period',
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    label: 'With Active Debt',
                    value: '${customers.customersWithDebt}',
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor:
                        hasDebt ? AppColors.danger : AppColors.success,
                    valueColor:
                        hasDebt ? AppColors.danger : AppColors.success,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    label: 'Outstanding Debt',
                    value: Formatters.formatCurrency(
                      customers.totalOutstandingDebt,
                      currency,
                    ),
                    icon: Icons.money_off_rounded,
                    accentColor:
                        debtPositive ? AppColors.danger : AppColors.gold,
                    valueColor:
                        debtPositive ? AppColors.danger : AppColors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTopCustomersSection(customers, currency),
            const SizedBox(height: 20),
            _buildCustomerDebtSection(customers, currency),
            const SizedBox(height: 20),
            VynexButton.secondary(
              label: 'Export Customer Report to Excel',
              icon: Icons.table_chart_outlined,
              isLoading: _exportingCustomers,
              onPressed: _exportCustomerReport,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCustomersSection(
    CustomerReportData customers,
    String currency,
  ) {
    final hasSpend = customers.topCustomers.any((c) => c.totalSpent > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.star_rounded, color: AppColors.gold, size: 18),
            SizedBox(width: 8),
            Text(
              'Top Customers',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.black,
              ),
            ),
            SizedBox(width: 6),
            Text(
              '(by spend in selected period)',
              style: TextStyle(color: AppColors.midGrey, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!hasSpend)
          const Text(
            'No customer purchases in this period.',
            style: TextStyle(color: AppColors.midGrey, fontSize: 12),
          )
        else
          ...List.generate(customers.topCustomers.length, (index) {
            final customer = customers.topCustomers[index];
            if (customer.totalSpent <= 0) {
              return const SizedBox.shrink();
            }
            final isFirst = index == 0;
            final initial = customer.customerName.isNotEmpty
                ? customer.customerName[0].toUpperCase()
                : '?';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => context.push(
                  '/customers/detail/${customer.customerId}',
                ),
                borderRadius: BorderRadius.circular(12),
                child: VynexCard(
                  child: Container(
                    color: isFirst
                        ? AppColors.gold.withValues(alpha: 0.1)
                        : null,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              AppColors.gold.withValues(alpha: 0.2),
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: AppColors.goldDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.customerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${customer.totalPurchases} purchases',
                                style: const TextStyle(
                                  color: AppColors.midGrey,
                                  fontSize: 11,
                                ),
                              ),
                              if (customer.lastPurchaseDate != null)
                                Text(
                                  'Last: ${Formatters.formatDate(customer.lastPurchaseDate!)}',
                                  style: const TextStyle(
                                    color: AppColors.midGrey,
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              Formatters.formatCurrency(
                                customer.totalSpent,
                                currency,
                              ),
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const Text(
                              'total spent',
                              style: TextStyle(
                                color: AppColors.midGrey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCustomerDebtSection(
    CustomerReportData customers,
    String currency,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: AppColors.danger,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Customers with Outstanding Debts',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (customers.customersWithActiveDebt.isEmpty)
          const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.gold,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'No customers have outstanding debts.',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                ),
              ),
            ],
          )
        else
          ...customers.customersWithActiveDebt.map((customer) {
            final initial = customer.customerName.isNotEmpty
                ? customer.customerName[0].toUpperCase()
                : '?';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: VynexCard(
                child: Container(
                  color: AppColors.danger.withValues(alpha: 0.06),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            AppColors.danger.withValues(alpha: 0.15),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${customer.debtCount} unpaid sale(s)',
                              style: const TextStyle(
                                color: AppColors.midGrey,
                                fontSize: 11,
                              ),
                            ),
                            if (customer.customerPhone != null &&
                                customer.customerPhone!.isNotEmpty)
                              Text(
                                customer.customerPhone!,
                                style: const TextStyle(
                                  color: AppColors.midGrey,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Formatters.formatCurrency(
                              customer.totalDebtBalance,
                              currency,
                            ),
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Text(
                            'owed',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.gold,
                          side: const BorderSide(color: AppColors.gold),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => context.push(
                          '/customers/detail/${customer.customerId}',
                        ),
                        child: const Text(
                          'View',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
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

  Widget _buildSaleSourceFilter(ReportProvider provider) {
    return VynexCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sale Source:',
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
                isActive: provider.saleSourceFilter == 'all',
                onTap: () => provider.setSaleSourceFilter('all'),
              ),
              _filterPill(
                label: 'From Stock',
                isActive: provider.saleSourceFilter == 'stock',
                onTap: () => provider.setSaleSourceFilter('stock'),
              ),
              _filterPill(
                label: 'Spot Buy',
                isActive: provider.saleSourceFilter == 'spot_buy',
                onTap: () => provider.setSaleSourceFilter('spot_buy'),
              ),
              _filterPill(
                label: 'Service',
                isActive: provider.saleSourceFilter == 'service',
                onTap: () => provider.setSaleSourceFilter('service'),
              ),
              _filterPill(
                label: 'Manual',
                isActive: provider.saleSourceFilter == 'manual',
                onTap: () => provider.setSaleSourceFilter('manual'),
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
            valueColor: AppColors.black,
          ),
        ],
      ),
    );
  }

  Widget _insightRow({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = AppColors.gold,
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
                style: TextStyle(
                  color: valueColor,
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

  Widget _buildSourceBreakdownChart(ReportData data) {
    final currency = context.read<SettingsProvider>().currencyLabel;
    final breakdown = data.sourceBreakdown;

    return VynexCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Row(
              children: [
                Text(
                  'Sales by Source',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (breakdown.totalCount == 0)
              const EmptyStateWidget(
                icon: Icons.pie_chart_outline_rounded,
                title: 'No source data',
                subtitle: 'Record sales to see breakdown',
              )
            else
              Row(
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: RepaintBoundary(
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 35,
                          sections: _buildPieSections(breakdown),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _legendItem(
                          'From Stock',
                          AppColors.success,
                          breakdown.stockCount,
                          breakdown.stockRevenue,
                          currency,
                        ),
                        _legendItem(
                          'Spot Buy',
                          AppColors.warning,
                          breakdown.spotBuyCount,
                          breakdown.spotBuyRevenue,
                          currency,
                        ),
                        _legendItem(
                          'Service',
                          const Color(0xFF9C27B0),
                          breakdown.serviceCount,
                          breakdown.serviceRevenue,
                          currency,
                        ),
                        _legendItem(
                          'Manual',
                          AppColors.midGrey,
                          breakdown.manualCount,
                          breakdown.manualRevenue,
                          currency,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
    SaleSourceBreakdown breakdown,
  ) {
    final total = breakdown.totalCount.toDouble();
    if (total == 0) {
      return [];
    }

    final sections = <PieChartSectionData>[];

    if (breakdown.stockCount > 0) {
      sections.add(
        PieChartSectionData(
          value: breakdown.stockCount.toDouble(),
          color: AppColors.success,
          title:
              '${((breakdown.stockCount / total) * 100).toStringAsFixed(0)}%',
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          radius: 50,
        ),
      );
    }

    if (breakdown.spotBuyCount > 0) {
      sections.add(
        PieChartSectionData(
          value: breakdown.spotBuyCount.toDouble(),
          color: AppColors.warning,
          title:
              '${((breakdown.spotBuyCount / total) * 100).toStringAsFixed(0)}%',
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          radius: 50,
        ),
      );
    }

    if (breakdown.serviceCount > 0) {
      sections.add(
        PieChartSectionData(
          value: breakdown.serviceCount.toDouble(),
          color: const Color(0xFF9C27B0),
          title:
              '${((breakdown.serviceCount / total) * 100).toStringAsFixed(0)}%',
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          radius: 50,
        ),
      );
    }

    if (breakdown.manualCount > 0) {
      sections.add(
        PieChartSectionData(
          value: breakdown.manualCount.toDouble(),
          color: AppColors.midGrey,
          title:
              '${((breakdown.manualCount / total) * 100).toStringAsFixed(0)}%',
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          radius: 50,
        ),
      );
    }

    return sections;
  }

  Widget _legendItem(
    String label,
    Color color,
    int count,
    double revenue,
    String currency,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$count sales | '
                  '${Formatters.compactCurrency(revenue, currency)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.midGrey,
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildExportSection(
    ReportData data, {
    required bool isExportingSales,
    required bool isExportingPurchases,
    required bool isExportingDebts,
    required Future<void> Function() onExportSales,
    required Future<void> Function() onExportPurchases,
    required Future<void> Function() onExportDebts,
  }) {
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
            isLoading: isExportingSales,
            onPressed: onExportSales,
          ),
          const SizedBox(height: 10),
          VynexButton.secondary(
            label: 'Export Purchases to Excel',
            icon: Icons.shopping_bag_rounded,
            isLoading: isExportingPurchases,
            onPressed: onExportPurchases,
          ),
          const SizedBox(height: 10),
          VynexButton.secondary(
            label: 'Export Debts to Excel',
            icon: Icons.account_balance_wallet_rounded,
            isLoading: isExportingDebts,
            onPressed: onExportDebts,
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
