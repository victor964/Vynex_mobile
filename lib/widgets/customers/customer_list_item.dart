// customer_list_item.dart
// Displays a single customer in the customers list.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../common/confirm_dialog.dart';

class CustomerListItem extends StatelessWidget {
  const CustomerListItem({
    super.key,
    required this.customer,
    this.lastPurchaseDate,
    this.hasOutstandingDebt = false,
  });

  final Customer customer;
  final String? lastPurchaseDate;
  final bool hasOutstandingDebt;

  @override
  Widget build(BuildContext context) {
    final initial = customer.name.isNotEmpty
        ? customer.name[0].toUpperCase()
        : '?';

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      shadowColor: AppColors.cardShadow,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(
          '${AppRoutes.customers}/detail/${customer.id}',
        ),
        onLongPress: () => _showOptionsSheet(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: const Border(
              left: BorderSide(color: AppColors.gold, width: 4),
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
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (customer.phone != null &&
                        customer.phone!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_rounded,
                            size: 12,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            customer.phone!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.midGrey,
                            ),
                          ),
                        ],
                      ),
                    if (customer.email != null &&
                        customer.email!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.email_rounded,
                            size: 12,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              customer.email!,
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
                    if ((customer.phone == null ||
                            customer.phone!.isEmpty) &&
                        (customer.email == null ||
                            customer.email!.isEmpty))
                      const Text(
                        'No contact info',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.midGrey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    if (lastPurchaseDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Last purchase: '
                        '${Formatters.formatDate(lastPurchaseDate!)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.midGrey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withValues(alpha: 0.15),
                      border: Border.all(
                        color: AppColors.gold,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  if (hasOutstandingDebt)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.danger,
                          border: Border.all(
                            color: AppColors.white,
                            width: 1.5,
                          ),
                        ),
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
                    context.push(
                      '${AppRoutes.addCustomer}?edit=${customer.id}',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.history_rounded,
                    color: AppColors.info,
                  ),
                  title: const Text('View History'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push(
                      '${AppRoutes.customers}/detail/${customer.id}',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                  ),
                  title: const Text('Delete'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _confirmDelete(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Customer?',
      message: 'Delete "${customer.name}"? Their sales will '
          'remain but will no longer be linked to this customer.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final success = await context
        .read<CustomerProvider>()
        .deleteCustomer(customer.id!);

    if (!context.mounted) return;

    if (success) {
      SnackBarHelper.showSuccess(context, 'Customer deleted');
    } else {
      SnackBarHelper.showError(
        context,
        'Failed to delete customer',
      );
    }
  }
}
