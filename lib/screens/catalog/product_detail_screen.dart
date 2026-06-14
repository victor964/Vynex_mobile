// Product detail screen with stock, pricing, and movement history.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/database/database_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../models/stock_movement.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/catalog/stock_badge_widget.dart';
import '../../widgets/common/vynex_app_bar.dart';
import '../../widgets/common/vynex_card.dart';
import '../../widgets/inventory/movement_list_item.dart';
import '../../widgets/inventory/stock_level_indicator.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  List<StockMovement> _movements = [];
  Category? _category;
  bool _isLoading = true;

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
      final product = await db.getProductById(widget.productId);
      if (!mounted) return;

      if (product == null) {
        setState(() => _isLoading = false);
        return;
      }

      final movements = await db.getStockMovements(widget.productId);
      if (!mounted) return;

      final categoryProvider = context.read<CategoryProvider>();
      if (categoryProvider.categories.isEmpty) {
        await categoryProvider.loadCategories();
      }

      if (!mounted) return;

      setState(() {
        _product = product;
        _movements = movements.take(10).toList();
        _category = categoryProvider.getCategoryById(
          product.categoryId,
        );
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _stockColor(Product product) {
    if (product.isOutOfStock) return AppColors.danger;
    if (product.isLowStock) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: VynexAppBar(
          title: 'Product Details',
          showBack: true,
        ),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    final product = _product;
    if (product == null) {
      return const Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: VynexAppBar(
          title: 'Product Details',
          showBack: true,
        ),
        body: Center(child: Text('Product not found')),
      );
    }

    final currency = context.watch<SettingsProvider>().currencyLabel;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: VynexAppBar(
        title: 'Product Details',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppColors.gold),
            onPressed: () => context.push(
              '/catalog/edit/${product.id}',
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push(
                    '/inventory/adjust/${product.id}?mode=adjust',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    side: const BorderSide(color: AppColors.gold),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Adjust Stock'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push(
                    '/inventory/movements/${product.id}',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.midGrey,
                    side: const BorderSide(color: AppColors.midGrey),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('View All Movements'),
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
            VynexCard(
              hasAccent: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildCategoryChip(),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Stock',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.midGrey,
                              ),
                            ),
                            Text(
                              '${product.currentStock} ${product.unit}s',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: _stockColor(product),
                              ),
                            ),
                          ],
                        ),
                      ),
                      StockBadgeWidget(product: product),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StockLevelIndicator(
                    product: product,
                    showLabels: true,
                    height: 10,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.push(
                            '/inventory/adjust/${product.id}'
                            '?mode=add',
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('+ Add Stock'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.black,
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push(
                            '/inventory/adjust/${product.id}'
                            '?mode=remove',
                          ),
                          icon: const Icon(Icons.remove, size: 18),
                          label: const Text('- Remove Stock'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(
                              color: AppColors.danger,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Low stock alert: below '
                    '${product.lowStockThreshold} ${product.unit}s',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.midGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            VynexCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.sell_rounded,
                        color: AppColors.gold,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Pricing',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _detailRow(
                    'Default Cost Price',
                    Formatters.formatCurrency(
                      product.defaultCostPrice,
                      currency,
                    ),
                  ),
                  _detailRow(
                    'Default Selling Price',
                    Formatters.formatCurrency(
                      product.defaultSellingPrice,
                      currency,
                    ),
                    valueColor: AppColors.gold,
                    valueBold: true,
                  ),
                  _detailRow(
                    'Profit Per Unit',
                    Formatters.formatCurrency(
                      product.defaultProfitPerUnit,
                      currency,
                    ),
                    valueColor: product.defaultProfitPerUnit >= 0
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                  _detailRow(
                    'Total Stock Value',
                    Formatters.formatCurrency(
                      product.totalStockValue,
                      currency,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            VynexCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Product Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _detailRow(
                    'Category',
                    _category?.name ?? 'Uncategorized',
                  ),
                  _detailRow('Unit', product.unit),
                  _detailRow(
                    'Barcode',
                    product.barcode ?? 'No barcode',
                  ),
                  _detailRow(
                    'Description',
                    product.description ?? 'No description',
                  ),
                  _detailRow(
                    'Date Added',
                    Formatters.formatDate(product.dateAdded),
                  ),
                  _detailRow(
                    'Last Updated',
                    Formatters.formatDate(product.lastUpdated),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Stock Movements',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(
                    '/inventory/movements/${product.id}',
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(color: AppColors.goldOnLight),
                  ),
                ),
              ],
            ),
            if (_movements.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No stock movements recorded yet.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.midGrey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              VynexCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < _movements.length; i++)
                      MovementListItem(
                        movement: _movements[i],
                        showDivider: i < _movements.length - 1,
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip() {
    if (_category != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _category!.name,
          style: const TextStyle(fontSize: 11, color: AppColors.darkGrey),
        ),
      );
    }
    return const Text(
      'Uncategorized',
      style: TextStyle(fontSize: 11, color: AppColors.midGrey),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.midGrey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? AppColors.black,
                fontSize: 13,
                fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
