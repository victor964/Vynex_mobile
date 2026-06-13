// product_picker_sheet.dart
// Bottom sheet for searching and selecting a product
// from the catalog. Used when recording FROM STOCK sales.
// Returns the selected Product or null if cancelled.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/database/database_helper.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/permission_helper.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/product.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import 'stock_badge_widget.dart';
import '../common/empty_state_widget.dart';

class ProductPickerSheet extends StatefulWidget {
  const ProductPickerSheet({super.key});

  static Future<Product?> show(BuildContext context) async {
    return showModalBottomSheet<Product?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.90,
        child: const ProductPickerSheet(),
      ),
    );
  }

  @override
  State<ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<ProductPickerSheet> {
  final _searchController = TextEditingController();
  List<Product> _results = [];
  bool _isSearching = false;
  int? _categoryFilter;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
      _searchProducts('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchProducts(String query) async {
    setState(() {
      _isSearching = true;
      _query = query;
    });
    try {
      final db = DatabaseHelper();
      if (query.isEmpty) {
        _results = await db.getProducts();
      } else {
        _results = await db.searchProducts(query);
      }
      if (_categoryFilter != null) {
        _results = _results
            .where((p) => p.categoryId == _categoryFilter)
            .toList();
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _scanBarcode() async {
    final scanned = await PermissionHelper.scanBarcodeWithPermission(context);
    if (scanned == null || !mounted) return;

    final product = await DatabaseHelper().getProductByBarcode(scanned);
    if (!mounted) return;

    if (product != null) {
      Navigator.pop(context, product);
    } else {
      SnackBarHelper.showInfo(
        context,
        'No product found with this barcode. '
        'You can add it to your catalog or enter manually.',
      );
    }
  }

  void _onCategorySelected(int? categoryId) {
    setState(() => _categoryFilter = categoryId);
    _searchProducts(_query);
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currencyLabel;
    final categories = context.watch<CategoryProvider>().categories;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.midGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select Product',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.black),
                    onPressed: () => Navigator.pop(context, null),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gold, width: 1.5),
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
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search by name or barcode...',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: _searchProducts,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: AppColors.gold,
                        size: 22,
                      ),
                      tooltip: 'Scan barcode',
                      onPressed: _scanBarcode,
                    ),
                    if (_query.isNotEmpty)
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.gold,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _searchProducts('');
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CategoryChip(
                    label: 'All (${_results.length})',
                    isSelected: _categoryFilter == null,
                    onTap: () => _onCategorySelected(null),
                  ),
                  const SizedBox(width: 8),
                  ...categories.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _CategoryChip(
                        label: cat.name,
                        isSelected: _categoryFilter == cat.id,
                        onTap: () => _onCategorySelected(cat.id),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isSearching
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    )
                  : _results.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.search_off_rounded,
                          title: 'No products match your search',
                          subtitle: 'Try a different term or scan a barcode',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          itemCount: _results.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final product = _results[index];
                            final category = context
                                .read<CategoryProvider>()
                                .getCategoryById(product.categoryId);
                            return ProductPickerItem(
                              product: product,
                              categoryName: category?.name,
                              currencyLabel: currency,
                              onTap: () =>
                                  Navigator.pop(context, product),
                            );
                          },
                        ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, null);
                context.push(AppRoutes.addProduct);
              },
              child: const Text(
                'Product not in catalog? Add it first',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class ProductPickerItem extends StatelessWidget {
  const ProductPickerItem({
    super.key,
    required this.product,
    required this.currencyLabel,
    required this.onTap,
    this.categoryName,
  });

  final Product product;
  final String? categoryName;
  final String currencyLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.black,
                      ),
                    ),
                    if (categoryName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        categoryName!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.midGrey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StockBadgeWidget(product: product),
              const SizedBox(width: 8),
              Text(
                Formatters.formatCurrency(
                  product.defaultSellingPrice,
                  currencyLabel,
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.midGrey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.black : AppColors.darkGrey,
          ),
        ),
      ),
    );
  }
}
