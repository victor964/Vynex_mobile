// inventory_list_item.dart
// Displays a single product in the inventory list with
// full stock level information and quick actions.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../models/product.dart';
import '../../widgets/catalog/stock_badge_widget.dart';

class InventoryListItem extends StatelessWidget {
  const InventoryListItem({
    super.key,
    required this.product,
    this.categoryName,
  });

  final Product product;
  final String? categoryName;

  Color get _stockColor {
    if (product.isOutOfStock) return AppColors.danger;
    if (product.isLowStock) return AppColors.warning;
    return AppColors.success;
  }

  Color get _cardTint {
    if (product.isOutOfStock) {
      return AppColors.danger.withValues(alpha: 0.04);
    }
    if (product.isLowStock) {
      return AppColors.warning.withValues(alpha: 0.04);
    }
    return AppColors.white;
  }

  double get _progressValue {
    if (product.isOutOfStock) return 0.0;
    if (product.isLowStock) {
      return (product.currentStock /
              (product.lowStockThreshold * 3))
          .clamp(0.0, 0.4);
    }
    return (product.currentStock / (product.lowStockThreshold * 5))
        .clamp(0.4, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final productId = product.id!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: _cardTint,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        shadowColor: AppColors.cardShadow,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/catalog/detail/$productId'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            categoryName ?? 'Uncategorized',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.midGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StockBadgeWidget(product: product),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progressValue,
                    minHeight: 8,
                    backgroundColor: AppColors.lightGrey,
                    valueColor:
                        AlwaysStoppedAnimation(_stockColor),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${product.currentStock} '
                      '${product.unit}s in stock',
                      style: TextStyle(
                        fontSize: 12,
                        color: _stockColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Alert at ${product.lowStockThreshold}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.midGrey,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, color: AppColors.divider),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => context.push(
                          '/inventory/adjust/$productId'
                          '?mode=add',
                        ),
                        icon: const Icon(
                          Icons.add_circle_outline,
                          size: 16,
                          color: AppColors.goldOnLight,
                        ),
                        label: const Text(
                          '+ Add Stock',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.goldOnLight,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: AppColors.divider,
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => context.push(
                          '/inventory/adjust/$productId'
                          '?mode=adjust',
                        ),
                        icon: const Icon(
                          Icons.tune,
                          size: 16,
                          color: AppColors.midGrey,
                        ),
                        label: const Text(
                          'Adjust',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.midGrey,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: AppColors.divider,
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => context.push(
                          '/inventory/movements/$productId',
                        ),
                        icon: const Icon(
                          Icons.history_rounded,
                          size: 16,
                          color: AppColors.midGrey,
                        ),
                        label: const Text(
                          'History',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.midGrey,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
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
