// Customer detail screen with profile, stats and full history.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/database/database_helper.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/debug_log.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/customer.dart';
import '../../models/customer_history.dart';
import '../../models/debt_with_sale.dart';
import '../../models/invoice.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/vynex_app_bar.dart';
import '../../widgets/common/vynex_card.dart';
import '../../widgets/customers/customer_history_item.dart';

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final int customerId;

  @override
  State<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  Customer? _customer;
  CustomerHistory? _history;
  List<DebtWithSale> _activeDebts = [];
  List<DebtWithSale> _clearedDebts = [];
  List<Invoice> _customerInvoices = [];
  bool _isLoading = true;
  bool _clearedExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      final db = DatabaseHelper();
      final customer = await db.getCustomerById(widget.customerId);
      final history = await db.getCustomerHistory(widget.customerId);
      final activeDebts = await db.getCustomerDebts(
        widget.customerId,
        activeOnly: true,
      );
      final clearedDebts = await db.getCustomerDebts(
        widget.customerId,
        clearedOnly: true,
      );
      final customerInvoices = await db.getInvoicesForCustomer(
        widget.customerId,
      );

      if (mounted) {
        setState(() {
          _customer = customer;
          _history = history;
          _activeDebts = activeDebts;
          _clearedDebts = clearedDebts;
          _customerInvoices = customerInvoices;
          _isLoading = false;
        });
      }
    } catch (e) {
      logDebug('Customer detail load error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(
          context,
          'Could not load customer details.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: VynexAppBar(
          title: 'Customer',
          showBack: true,
        ),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    final customer = _customer;
    final history = _history;

    if (customer == null || history == null) {
      return const Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: VynexAppBar(
          title: 'Customer',
          showBack: true,
        ),
        body: Center(child: Text('Customer not found')),
      );
    }

    final currency = context.watch<SettingsProvider>().currencyLabel;
    final initial = customer.name.isNotEmpty
        ? customer.name[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: VynexAppBar(
        title: customer.name,
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.gold),
            onPressed: () => context.push(
              '${AppRoutes.addCustomer}?edit=${customer.id}',
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_activeDebts.isNotEmpty) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go(AppRoutes.debts),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'View Debts (${_activeDebts.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push(
                    '${AppRoutes.addSale}?customerId=${customer.id}',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.black,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'New Sale for Customer',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileCard(
              customer,
              history,
              currency,
              initial,
            ),
            if (history.favoriteItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildFavoriteItems(history, currency),
            ],
            const SizedBox(height: 16),
            _buildPurchaseHistory(history),
            if (_activeDebts.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildActiveDebts(currency),
            ],
            if (_clearedDebts.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildClearedDebts(currency),
            ],
            if (_customerInvoices.isNotEmpty) ...[
              const SizedBox(height: 16),
              VynexCard(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.receipt_long_rounded,
                            color: AppColors.gold,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Invoice History',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.black,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_customerInvoices.length} invoices',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.midGrey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      ..._customerInvoices.map(_buildInvoiceRow),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(Invoice invoice) {
    final currency =
        context.read<SettingsProvider>().currencyLabel;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_outlined,
            color: AppColors.gold,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.invoiceNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.black,
                  ),
                ),
                Text(
                  Formatters.formatDate(
                    invoice.dateIssued,
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.midGrey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Formatters.formatCurrency(
              invoice.total,
              currency,
            ),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              if (invoice.saleId != null) {
                context.push(
                  '/invoice/${invoice.saleId}',
                );
              }
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: AppColors.gold,
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Share',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
    Customer customer,
    CustomerHistory history,
    String currency,
    String initial,
  ) {
    return VynexCard(
      hasAccent: true,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.gold, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
                fontSize: 36,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            customer.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.black,
            ),
          ),
          if (customer.phone != null && customer.phone!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                customer.phone!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.midGrey,
                ),
              ),
            ),
          if (customer.email != null && customer.email!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                customer.email!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.midGrey,
                ),
              ),
            ),
          if (customer.notes != null && customer.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.gold, height: 1),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                customer.notes!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.midGrey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _statGridItem(
                icon: Icons.shopping_bag_rounded,
                label: 'Total Purchases',
                value: '${history.totalSalesCount} transactions',
                color: AppColors.gold,
              ),
              _statGridItem(
                icon: Icons.payments_rounded,
                label: 'Total Spent',
                value: Formatters.formatCurrency(
                  history.totalAmountSpent,
                  currency,
                ),
                color: AppColors.gold,
              ),
              _statGridItem(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Outstanding Debt',
                value: Formatters.formatCurrency(
                  history.outstandingDebtBalance,
                  currency,
                ),
                color: history.outstandingDebtBalance > 0
                    ? AppColors.danger
                    : AppColors.success,
              ),
              _statGridItem(
                icon: Icons.calendar_today_rounded,
                label: 'Last Purchase',
                value: history.lastPurchaseDate != null
                    ? Formatters.formatDate(history.lastPurchaseDate!)
                    : 'Never',
                color: AppColors.gold,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statGridItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.midGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteItems(
    CustomerHistory history,
    String currency,
  ) {
    return VynexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star_rounded, color: AppColors.gold, size: 18),
              SizedBox(width: 8),
              Text(
                'Frequently Bought',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...history.favoriteItems.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final item = entry.value;
            final isLast = rank == history.favoriteItems.length;
            return Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item['item_name'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      '${item['total_qty']} units',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.midGrey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Formatters.formatCurrency(
                        (item['total_spent'] as num).toDouble(),
                        currency,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
                if (!isLast)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: AppColors.divider),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPurchaseHistory(CustomerHistory history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.shopping_bag_rounded,
              color: AppColors.gold,
              size: 18,
            ),
            const SizedBox(width: 8),
            const Text(
              'Purchase History',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.black,
              ),
            ),
            const Spacer(),
            Text(
              '${history.totalSalesCount} transactions',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.midGrey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (history.recentSales.isEmpty)
          const Text(
            'No purchases recorded yet.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.midGrey,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          ...history.recentSales.asMap().entries.map((entry) {
            final sale = entry.value;
            final isLast = entry.key == history.recentSales.length - 1;
            final hasDebt = _activeDebts.any(
              (d) => d.debt.saleId == sale.id,
            );
            return CustomerHistoryItem(
              sale: sale,
              isLast: isLast,
              hasLinkedDebt: hasDebt && !sale.isFullyPaid,
            );
          }),
      ],
    );
  }

  Widget _buildActiveDebts(String currency) {
    final history = _history!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.danger,
              size: 18,
            ),
            const SizedBox(width: 8),
            const Text(
              'Pending Debts',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.danger,
              ),
            ),
            const Spacer(),
            Text(
              '${Formatters.formatCurrency(
                history.outstandingDebtBalance,
                currency,
              )} owed',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._activeDebts.map(
          (row) => _DebtRowCard(
            row: row,
            currency: currency,
            isCleared: false,
          ),
        ),
      ],
    );
  }

  Widget _buildClearedDebts(String currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(
            () => _clearedExpanded = !_clearedExpanded,
          ),
          child: Row(
            children: [
              const Text(
                'Cleared Debts',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.black,
                ),
              ),
              const Spacer(),
              Icon(
                _clearedExpanded
                    ? Icons.expand_less
                    : Icons.expand_more,
                color: AppColors.midGrey,
              ),
            ],
          ),
        ),
        if (_clearedExpanded) ...[
          const SizedBox(height: 12),
          ..._clearedDebts.map(
            (row) => _DebtRowCard(
              row: row,
              currency: currency,
              isCleared: true,
            ),
          ),
        ],
      ],
    );
  }
}

class _DebtRowCard extends StatelessWidget {
  const _DebtRowCard({
    required this.row,
    required this.currency,
    required this.isCleared,
  });

  final DebtWithSale row;
  final String currency;
  final bool isCleared;

  @override
  Widget build(BuildContext context) {
    final debt = row.debt;
    final bgColor = isCleared
        ? AppColors.success.withValues(alpha: 0.06)
        : AppColors.danger.withValues(alpha: 0.06);
    final borderColor =
        isCleared ? AppColors.success : AppColors.danger;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.push('/debt/detail/${debt.id}'),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.itemName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      Formatters.formatCurrency(
                        debt.balance,
                        currency,
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isCleared
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      Formatters.formatDate(debt.dateCreated),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.midGrey,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isCleared
                            ? AppColors.success
                            : AppColors.danger,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isCleared ? 'CLEARED' : 'UNPAID',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
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
  }
}
