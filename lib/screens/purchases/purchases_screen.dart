// Purchases list screen with search, month filter, and table view.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/purchase.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/vynex_app_bar.dart';
import '../../widgets/common/vynex_button.dart';
import '../../widgets/common/vynex_card.dart';

/// Purchases list screen and module entry point.
class PurchasesScreen extends StatefulWidget {
  /// Creates the purchases screen.
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  String _searchQuery = '';
  String _selectedMonth = 'all';
  List<Purchase> _filteredPurchases = [];
  double _filteredTotalSpent = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final purchaseProvider = context.read<PurchaseProvider>();
      final settingsProvider = context.read<SettingsProvider>();
      await purchaseProvider.loadPurchases();
      await settingsProvider.loadSettings();
      if (mounted) _applyFilters();
    });
  }

  void _applyFilters() {
    final provider = context.read<PurchaseProvider>();
    var filtered = provider.purchases;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (p) => p.itemName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    if (_selectedMonth != 'all') {
      filtered = filtered
          .where((p) => p.datePurchased.startsWith(_selectedMonth))
          .toList();
    }

    setState(() {
      _filteredPurchases = filtered;
      _filteredTotalSpent = filtered.fold(
        0.0,
        (sum, p) => sum + p.totalCost,
      );
    });
  }

  List<String> _getAvailableMonths(List<Purchase> purchases) {
    final months = purchases
        .map((p) => p.datePurchased.substring(0, 7))
        .toSet()
        .toList();
    months.sort((a, b) => b.compareTo(a));
    return months;
  }

  String _formatMonthLabel(String yyyyMm) {
    return DateFormat('MMM yyyy')
        .format(DateTime.parse('$yyyyMm-01'));
  }

  Future<void> _onRefresh() async {
    await context.read<PurchaseProvider>().loadPurchases();
    _applyFilters();
  }

  Future<void> _showPurchaseSheet(
    BuildContext context,
    Purchase purchase,
  ) async {
    final currency = context.read<SettingsProvider>().currencyLabel;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  purchase.itemName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 12),
                _SheetRow(
                  label: 'Quantity',
                  value: '${purchase.quantity}',
                ),
                _SheetRow(
                  label: 'Cost Per Unit',
                  value: Formatters.formatCurrency(
                    purchase.costPrice,
                    currency,
                  ),
                ),
                _SheetRow(
                  label: 'Total Cost',
                  value: Formatters.formatCurrency(
                    purchase.totalCost,
                    currency,
                  ),
                  valueColor: AppColors.gold,
                ),
                _SheetRow(
                  label: 'Date',
                  value: Formatters.formatDate(purchase.datePurchased),
                ),
                if (purchase.notes != null &&
                    purchase.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.midGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    purchase.notes!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.darkGrey,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                VynexButton.primary(
                  label: 'Edit',
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    context.push('/purchases/edit/${purchase.id}');
                  },
                ),
                const SizedBox(height: 8),
                VynexButton.danger(
                  label: 'Delete',
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    await _confirmDelete(context, purchase);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Purchase purchase,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Purchase',
      message: "Delete '${purchase.itemName}'? This cannot be undone.",
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final success = await context.read<PurchaseProvider>().deletePurchase(
          purchase.id!,
        );
    if (!context.mounted) return;

    if (success) {
      SnackBarHelper.showSuccess(context, 'Purchase deleted');
      _applyFilters();
    } else {
      SnackBarHelper.showError(
        context,
        'Failed to delete purchase. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currencyLabel;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: VynexAppBar(
        title: 'Purchases',
        showSettings: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.gold),
            onPressed: () => context.push(AppRoutes.addPurchase),
          ),
        ],
      ),
      body: Consumer<PurchaseProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.purchases.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          if (provider.purchases.isEmpty) {
            return RefreshIndicator(
              color: AppColors.gold,
              onRefresh: _onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  EmptyStateWidget(
                    icon: Icons.shopping_bag_outlined,
                    title: 'No purchases recorded',
                    subtitle: 'Tap the + button to record your first purchase',
                  ),
                ],
              ),
            );
          }

          final months = _getAvailableMonths(provider.purchases);

          return RefreshIndicator(
            color: AppColors.gold,
            onRefresh: _onRefresh,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.gold,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Icon(
                            Icons.search,
                            color: AppColors.gold,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search item name...',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                              _applyFilters();
                            },
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.gold,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() => _searchQuery = '');
                              _applyFilters();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                if (months.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _MonthPill(
                          label: 'All',
                          isSelected: _selectedMonth == 'all',
                          onTap: () {
                            setState(() => _selectedMonth = 'all');
                            _applyFilters();
                          },
                        ),
                        ...months.map(
                          (m) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _MonthPill(
                              label: _formatMonthLabel(m),
                              isSelected: _selectedMonth == m,
                              onTap: () {
                                setState(() => _selectedMonth = m);
                                _applyFilters();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _selectedMonth != 'all'
                            ? 'Total spent in '
                                '${_formatMonthLabel(_selectedMonth)}: '
                                '${Formatters.formatCurrency(
                                  _filteredTotalSpent,
                                  currency,
                                )}'
                            : 'Total spent (all time): '
                                '${Formatters.formatCurrency(
                                  _filteredTotalSpent,
                                  currency,
                                )}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: VynexCard(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Showing ${_filteredPurchases.length} records | '
                      'Total: ${Formatters.formatCurrency(
                        _filteredTotalSpent,
                        currency,
                      )}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _filteredPurchases.isEmpty
                      ? _buildEmptyFiltered(context)
                      : _buildTable(context, currency),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyFiltered(BuildContext context) {
    if (_searchQuery.isNotEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                Text(
                  "No purchases match '$_searchQuery'",
                  style: const TextStyle(color: AppColors.midGrey),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() => _searchQuery = '');
                    _applyFilters();
                  },
                  child: const Text(
                    'Clear search',
                    style: TextStyle(color: AppColors.gold),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 80),
        EmptyStateWidget(
          icon: Icons.shopping_bag_outlined,
          title: 'No purchases match filters',
          subtitle: 'Try a different month or search term',
        ),
      ],
    );
  }

  Widget _buildTable(BuildContext context, String currency) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TableHeader(),
            ..._filteredPurchases.asMap().entries.map((entry) {
              final index = entry.key;
              final purchase = entry.value;
              return _TableDataRow(
                purchase: purchase,
                currency: currency,
                isAlt: index.isOdd,
                onTap: () => _showPurchaseSheet(context, purchase),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MonthPill extends StatelessWidget {
  const _MonthPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.black : AppColors.gold,
          ),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: AppColors.black,
      child: const Row(
        children: [
          _HeaderCell(label: 'Item', width: 140, flex: true),
          _HeaderCell(label: 'Qty', width: 45),
          _HeaderCell(label: 'Cost/Unit', width: 80),
          _HeaderCell(label: 'Total Cost', width: 80),
          _HeaderCell(label: 'Date', width: 75),
          _HeaderCell(label: 'Note', width: 60),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.label,
    this.width,
    this.flex = false,
  });

  final String label;
  final double? width;
  final bool flex;

  @override
  Widget build(BuildContext context) {
    final child = Text(
      label,
      style: const TextStyle(
        color: AppColors.gold,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      textAlign: flex ? TextAlign.left : TextAlign.center,
    );
    if (flex) {
      return SizedBox(width: width, child: child);
    }
    return SizedBox(
      width: width,
      child: Center(child: child),
    );
  }
}

class _TableDataRow extends StatelessWidget {
  const _TableDataRow({
    required this.purchase,
    required this.currency,
    required this.isAlt,
    required this.onTap,
  });

  final Purchase purchase;
  final String currency;
  final bool isAlt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasNote =
        purchase.notes != null && purchase.notes!.trim().isNotEmpty;

    return Material(
      color: isAlt ? AppColors.lightGrey : AppColors.white,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              SizedBox(
                width: 140,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    purchase.itemName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 45,
                child: Text(
                  '${purchase.quantity}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  Formatters.formatCurrency(purchase.costPrice, currency),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  Formatters.formatCurrency(purchase.totalCost, currency),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
              ),
              SizedBox(
                width: 75,
                child: Text(
                  Formatters.formatDate(purchase.datePurchased),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.midGrey,
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Center(
                  child: hasNote
                      ? const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.gold,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.midGrey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
