// Inventory overview screen with stock levels and filters.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/product.dart';
import '../../providers/category_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/common/vynex_app_bar.dart';
import '../../widgets/inventory/inventory_list_item.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _filter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadInventory();
      final categoryProvider = context.read<CategoryProvider>();
      if (categoryProvider.categories.isEmpty) {
        categoryProvider.loadCategories();
      }
    });
  }

  void _cycleFilter() {
    setState(() {
      switch (_filter) {
        case 'all':
          _filter = 'low';
        case 'low':
          _filter = 'out';
        case 'out':
          _filter = 'all';
      }
    });
  }

  String get _filterBadgeLabel {
    switch (_filter) {
      case 'low':
        return 'L';
      case 'out':
        return 'O';
      default:
        return 'A';
    }
  }

  List<Product> _filteredProducts(InventoryProvider provider) {
    List<Product> base;
    switch (_filter) {
      case 'low':
        base = provider.lowStockProducts;
      case 'out':
        base = provider.outOfStockProducts;
      default:
        base = provider.allProducts;
    }
    if (_searchQuery.trim().isEmpty) return base;
    final query = _searchQuery.toLowerCase();
    return base
        .where(
          (p) => p.name.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currencyLabel;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: VynexAppBar(
        title: 'Inventory',
        showBack: true,
        actions: [
          IconButton(
            onPressed: _cycleFilter,
            icon: Badge(
              label: Text(
                _filterBadgeLabel,
                style: const TextStyle(fontSize: 9),
              ),
              backgroundColor: AppColors.gold,
              child: const Icon(
                Icons.filter_list,
                color: AppColors.gold,
              ),
            ),
          ),
        ],
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.allProducts.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.gold,
              ),
            );
          }

          final products = _filteredProducts(provider);

          return RefreshIndicator(
            color: AppColors.gold,
            onRefresh: provider.loadInventory,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSummaryGrid(provider, currency),
                        const SizedBox(height: 8),
                        _buildRetailStrip(provider, currency),
                        const SizedBox(height: 16),
                        _buildFilterPills(),
                        const SizedBox(height: 12),
                        _buildSearchBar(),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                if (products.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = products[index];
                          final categoryName = context
                              .read<CategoryProvider>()
                              .getCategoryById(product.categoryId)
                              ?.name;
                          return InventoryListItem(
                            product: product,
                            categoryName: categoryName,
                          );
                        },
                        childCount: products.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryGrid(
    InventoryProvider provider,
    String currency,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: [
        StatCard(
          label: 'Total Products',
          value: '${provider.totalProducts}',
          icon: Icons.inventory_2_rounded,
        ),
        StatCard(
          label: 'Stock Value',
          value: Formatters.formatCurrency(
            provider.totalInventoryValue,
            currency,
          ),
          icon: Icons.paid_rounded,
          subtitle: 'at cost price',
        ),
        StatCard(
          label: 'Low Stock',
          value: '${provider.lowStockCount}',
          icon: Icons.warning_amber_rounded,
          accentColor: AppColors.warning,
          valueColor: provider.lowStockCount > 0
              ? AppColors.warning
              : AppColors.midGrey,
        ),
        StatCard(
          label: 'Out of Stock',
          value: '${provider.outOfStockCount}',
          icon: Icons.remove_shopping_cart_rounded,
          accentColor: AppColors.danger,
          valueColor: provider.outOfStockCount > 0
              ? AppColors.danger
              : AppColors.midGrey,
        ),
      ],
    );
  }

  Widget _buildRetailStrip(
    InventoryProvider provider,
    String currency,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Retail value: '
          '${Formatters.formatCurrency(provider.totalRetailValue, currency)}',
          style: const TextStyle(
            color: AppColors.gold,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          'Potential earnings if all stock is sold',
          style: TextStyle(
            color: AppColors.midGrey,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPills() {
    return Row(
      children: [
        _filterPill('All Products', 'all'),
        const SizedBox(width: 8),
        _filterPill('Low Stock', 'low'),
        const SizedBox(width: 8),
        _filterPill('Out of Stock', 'out'),
      ],
    );
  }

  Widget _filterPill(String label, String value) {
    final selected = _filter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.gold : AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.gold,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.black : AppColors.gold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold, width: 1.5),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(Icons.search, color: AppColors.gold, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search products...',
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.gold, size: 20),
              onPressed: () => setState(() => _searchQuery = ''),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    switch (_filter) {
      case 'low':
        return const EmptyStateWidget(
          icon: Icons.check_circle_outline,
          title: 'No low stock items. Your inventory looks good!',
          subtitle: '',
        );
      case 'out':
        return const EmptyStateWidget(
          icon: Icons.check_circle,
          title: 'No out of stock items. Great job keeping stock!',
          subtitle: '',
        );
      default:
        return EmptyStateWidget(
          icon: Icons.inventory_2_outlined,
          title: 'No products in inventory.',
          subtitle: 'Add products to your catalog to track stock.',
          actionLabel: 'Go to Catalog',
          onAction: () => context.go(AppRoutes.catalog),
        );
    }
  }
}
