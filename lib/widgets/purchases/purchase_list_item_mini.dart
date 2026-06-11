// Compact purchase row for dashboard recent purchases list.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/purchase.dart';
import '../../providers/settings_provider.dart';

/// Compact purchase list item for the dashboard.
class PurchaseListItemMini extends StatelessWidget {
  /// Creates a mini purchase list item.
  const PurchaseListItemMini({super.key, required this.purchase});

  final Purchase purchase;

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currencyLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        elevation: 1,
        shadowColor: AppColors.cardShadow,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purchase.itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatDate(purchase.datePurchased),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.midGrey,
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                Formatters.formatCurrency(
                  purchase.totalCost,
                  currency,
                ),
                style: const TextStyle(
                  color: AppColors.darkGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
