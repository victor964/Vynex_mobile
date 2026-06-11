// Full list item card for a single purchase record.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/purchase.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/settings_provider.dart';
import '../common/confirm_dialog.dart';

/// List item card for one purchase with edit and delete actions.
class PurchaseListItem extends StatelessWidget {
  /// Creates a purchase list item.
  const PurchaseListItem({super.key, required this.purchase});

  final Purchase purchase;

  Future<void> _showOptions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.gold),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(
                    '/purchases/edit/${purchase.id}',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.danger),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _confirmDelete(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Purchase',
      message: "Delete '${purchase.itemName}'? This cannot be undone.",
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final success = await context.read<PurchaseProvider>().deletePurchase(
          purchase.id!,
        );
    if (!context.mounted) return;

    if (success) {
      SnackBarHelper.showSuccess(context, 'Purchase deleted');
    } else {
      SnackBarHelper.showError(
        context,
        'Failed to delete purchase. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currencyLabel;

    return GestureDetector(
      onTap: () => _showOptions(context),
      onLongPress: () => _showOptions(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: const Border(
            left: BorderSide(color: AppColors.gold, width: 4),
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    purchase.itemName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 13,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        Formatters.formatDate(purchase.datePurchased),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.midGrey,
                        ),
                      ),
                    ],
                  ),
                  if (purchase.notes != null &&
                      purchase.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 12,
                          color: AppColors.midGrey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            purchase.notes!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.midGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.formatCurrency(
                    purchase.totalCost,
                    currency,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${purchase.quantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.midGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@$currency ${Formatters.formatNumber(purchase.costPrice)}/unit',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.midGrey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
