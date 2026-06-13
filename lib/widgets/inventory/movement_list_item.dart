// movement_list_item.dart
// Displays a single stock movement entry.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/stock_movement.dart';

class MovementListItem extends StatelessWidget {
  const MovementListItem({
    super.key,
    required this.movement,
    this.showDivider = true,
  });

  final StockMovement movement;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final iconData = _iconForType(movement.movementType);
    final iconColor = _iconColor(movement.movementType);
    final qtyText = _quantityText();
    final qtyColor = _quantityColor();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(iconData, color: iconColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movement.typeLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.black,
                      ),
                    ),
                    if (movement.note != null &&
                        movement.note!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        movement.note!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.midGrey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    qtyText,
                    style: TextStyle(
                      color: qtyColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.formatDate(movement.dateRecorded),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.midGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            color: AppColors.lightGrey,
          ),
      ],
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'restock':
        return Icons.arrow_downward_rounded;
      case 'sale':
        return Icons.arrow_upward_rounded;
      case 'adjustment':
        return Icons.tune_rounded;
      case 'initial':
        return Icons.add_circle_rounded;
      default:
        return Icons.swap_horiz_rounded;
    }
  }

  Color _iconColor(String type) {
    switch (type) {
      case 'restock':
        return AppColors.success;
      case 'sale':
        return AppColors.danger;
      case 'adjustment':
        return AppColors.info;
      case 'initial':
        return AppColors.gold;
      default:
        return AppColors.midGrey;
    }
  }

  String _quantityText() {
    final qty = movement.quantity;
    switch (movement.movementType) {
      case 'restock':
      case 'initial':
        return '+$qty';
      case 'sale':
        return '-$qty';
      case 'adjustment':
        return qty > 0 ? '+$qty' : '$qty';
      default:
        return '$qty';
    }
  }

  Color _quantityColor() {
    switch (movement.movementType) {
      case 'restock':
      case 'initial':
        return AppColors.success;
      case 'sale':
        return AppColors.danger;
      case 'adjustment':
        return movement.quantity > 0
            ? AppColors.success
            : AppColors.danger;
      default:
        return AppColors.black;
    }
  }
}
