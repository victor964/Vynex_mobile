// Catalog list screen with search, category filter, and product list.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/catalog/product_list_item.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/vynex_app_bar.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      context.read<CategoryProvider>().loadCategories();
    });
  }

  Future<void> _onRefresh() async {
    if (!mounted) return;
    await context.read<ProductProvider>().loadProducts();
    if (!mounted) return;
    await context.read<CategoryProvider>().loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: VynexAppBar(
        title: 'Product Catalog',
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.gold),
            onPressed: () => context.push(AppRoutes.addProduct),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.black,
        onPressed: () => context.push(AppRoutes.addProduct),
        child: const Icon(Icons.add),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, _) {
          if (productProvider.isLoading &&
              productProvider.products.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          return RefreshIndicator(
            color: AppColors.gold,
            onRefresh: _onRefresh,
            child: Column(
              children: [
                _buildSearchBar(productProvider),
                _buildCategoryChips(productProvider),
                _buildSummaryStrip(productProvider),
                Expanded(child: _buildProductList(productProvider)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(ProductProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
              child: Icon(Icons.search, color: AppColors.gold, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by name or barcode...',
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: provider.setSearchQuery,
              ),
            ),
            if (provider.searchQuery.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.gold, size: 20),
                onPressed: () => provider.setSearchQuery(''),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips(ProductProvider productProvider) {
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = categoryProvider.categories;
    final selectedId = productProvider.selectedCategoryId;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 32,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _CategoryChip(
              label: 'All (${productProvider.totalProducts})',
              isSelected: selectedId == null,
              onTap: () => productProvider.setCategoryFilter(null),
            ),
            const SizedBox(width: 8),
            ...categories.map((cat) {
              final count = productProvider.countInCategory(cat.id);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _CategoryChip(
                  label: '${cat.name} ($count)',
                  isSelected: selectedId == cat.id,
                  onTap: () => productProvider.setCategoryFilter(cat.id),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStrip(ProductProvider provider) {
    final filtered = provider.filteredProducts.length;
    final total = provider.totalProducts;
    final hasAlerts =
        provider.outOfStockCount > 0 || provider.lowStockCount > 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Showing $filtered of $total products',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.darkGrey,
            ),
          ),
          if (hasAlerts) ...[
            const SizedBox(height: 2),
            Text(
              '${provider.outOfStockCount} out of stock | '
              '${provider.lowStockCount} low stock',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductList(ProductProvider provider) {
    final products = provider.filteredProducts;
    final categoryProvider = context.watch<CategoryProvider>();
    final hasSearch = provider.searchQuery.isNotEmpty;

    if (products.isEmpty && hasSearch) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 60),
          EmptyStateWidget(
            icon: Icons.search_off_rounded,
            title: 'No products found',
            subtitle: 'Try a different search term',
          ),
        ],
      );
    }

    if (products.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 60),
          EmptyStateWidget(
            icon: Icons.inventory_2_outlined,
            title: 'No products yet',
            subtitle: 'Tap + to add your first product to the catalog',
            actionLabel: 'Add Product',
            onAction: () => context.push(AppRoutes.addProduct),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final product = products[index];
        final category = categoryProvider.getCategoryById(
          product.categoryId,
        );
        return ProductListItem(
          product: product,
          categoryName: category?.name,
        );
      },
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
