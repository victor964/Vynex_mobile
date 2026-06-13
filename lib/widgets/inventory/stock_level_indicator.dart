// stock_level_indicator.dart
// Visual stock level bar with color coding.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/product.dart';

class StockLevelIndicator extends StatelessWidget {
  final Product product;
  final bool showLabels;
  final double height;

  const StockLevelIndicator({
    super.key,
    required this.product,
    this.showLabels = true,
    this.height = 8,
  });

  double get _progress {
    if (product.isOutOfStock) return 0.0;
    final maxStock = product.lowStockThreshold * 5.0;
    return (product.currentStock / maxStock).clamp(0.0, 1.0);
  }

  Color get _color {
    if (product.isOutOfStock) return AppColors.danger;
    if (product.isLowStock) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: AppColors.lightGrey,
            valueColor: AlwaysStoppedAnimation(_color),
            minHeight: height,
          ),
        ),
        if (showLabels) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                product.isOutOfStock
                    ? 'Out of stock'
                    : '${product.currentStock} '
                        '${product.unit}s in stock',
                style: TextStyle(
                  fontSize: 11,
                  color: _color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Alert: ${product.lowStockThreshold}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.midGrey,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
