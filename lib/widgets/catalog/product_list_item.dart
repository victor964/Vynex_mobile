// product_list_item.dart
// Displays a single product in the catalog list.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../common/confirm_dialog.dart';
import 'stock_badge_widget.dart';

class ProductListItem extends StatelessWidget {
  const ProductListItem({
    super.key,
    required this.product,
    this.categoryName,
  });

  final Product product;
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currencyLabel;
    final borderColor = _stockBorderColor(product);

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      shadowColor: AppColors.cardShadow,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(
          '/catalog/detail/${product.id}',
        ),
        onLongPress: () => _showOptionsSheet(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: borderColor, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildCategoryChip(),
                    const SizedBox(height: 4),
                    _buildBarcodeRow(),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StockBadgeWidget(product: product),
                  const SizedBox(height: 6),
                  Text(
                    Formatters.formatCurrency(
                      product.defaultSellingPrice,
                      currency,
                    ),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Cost: ${Formatters.formatCurrency(
                      product.defaultCostPrice,
                      currency,
                    )}',
                    style: const TextStyle(
                      color: AppColors.midGrey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip() {
    if (categoryName != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          categoryName!,
          style: const TextStyle(fontSize: 11, color: AppColors.darkGrey),
        ),
      );
    }
    return const Text(
      'Uncategorized',
      style: TextStyle(fontSize: 11, color: AppColors.midGrey),
    );
  }

  Widget _buildBarcodeRow() {
    if (product.barcode != null && product.barcode!.isNotEmpty) {
      final display = product.barcode!.length > 12
          ? '${product.barcode!.substring(0, 12)}...'
          : product.barcode!;
      return Row(
        children: [
          const Icon(Icons.qr_code, size: 12, color: AppColors.midGrey),
          const SizedBox(width: 4),
          Text(
            display,
            style: const TextStyle(fontSize: 11, color: AppColors.midGrey),
          ),
        ],
      );
    }
    return const Row(
      children: [
        Icon(Icons.label_off_outlined, size: 12, color: AppColors.midGrey),
        SizedBox(width: 4),
        Text(
          'No barcode',
          style: TextStyle(fontSize: 11, color: AppColors.midGrey),
        ),
      ],
    );
  }

  Color _stockBorderColor(Product product) {
    if (product.isOutOfStock) return AppColors.danger;
    if (product.isLowStock) return AppColors.warning;
    return AppColors.success;
  }

  Future<void> _showOptionsSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.edit_rounded,
                    color: AppColors.gold,
                  ),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push('/catalog/edit/${product.id}');
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.tune_rounded,
                    color: AppColors.info,
                  ),
                  title: const Text('Adjust Stock'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push(
                      '/inventory/adjust/${product.id}',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.remove_circle_outline,
                    color: AppColors.danger,
                  ),
                  title: const Text('Remove from Catalog'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _confirmDeactivate(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeactivate(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove from Catalog?',
      message: 'Remove "${product.name}" from the catalog? '
          'Past sales and purchases are not affected.',
      confirmLabel: 'Remove',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final success = await context
        .read<ProductProvider>()
        .deactivateProduct(product.id!);

    if (!context.mounted) return;

    if (success) {
      SnackBarHelper.showSuccess(
        context,
        'Product removed from catalog',
      );
    } else {
      SnackBarHelper.showError(
        context,
        'Failed to remove product',
      );
    }
  }
}
