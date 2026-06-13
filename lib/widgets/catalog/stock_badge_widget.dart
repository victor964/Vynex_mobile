// stock_badge_widget.dart
// Shows stock level as a colored pill badge.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/product.dart';

class StockBadgeWidget extends StatelessWidget {
  final Product product;
  final bool showLabel;

  const StockBadgeWidget({
    super.key,
    required this.product,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = product.isOutOfStock
        ? AppColors.danger
        : product.isLowStock
            ? AppColors.warning
            : AppColors.success;

    final label = product.isOutOfStock
        ? 'Out of Stock'
        : product.isLowStock
            ? 'Low: ${product.currentStock} ${product.unit}s'
            : '${product.currentStock} ${product.unit}s';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
