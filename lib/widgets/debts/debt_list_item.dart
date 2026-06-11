// List item card for a debt with sale context and payment actions.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/debt.dart';
import '../../models/debt_with_sale.dart';
import '../../providers/debt_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/settings_provider.dart';
import '../common/confirm_dialog.dart';

/// Card for one debt in the pending or cleared list.
class DebtListItem extends StatelessWidget {
  /// Creates a debt list item.
  const DebtListItem({
    super.key,
    required this.item,
    required this.isCleared,
  });

  final DebtWithSale item;
  final bool isCleared;

  void _openDetail(BuildContext context) {
    final id = item.debt.id;
    if (id == null) return;
    context.push('/debt/detail/$id');
  }

  Future<void> _markCleared(BuildContext context) async {
    final id = item.debt.id;
    if (id == null) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Mark as Cleared',
      message:
          'Mark this debt as fully paid? This will set the balance to zero.',
      confirmLabel: 'Yes, Clear It',
    );
    if (!confirmed || !context.mounted) return;

    final success = await context.read<DebtProvider>().markDebtCleared(id);
    if (!context.mounted) return;

    if (!context.mounted) return;

    if (success) {
      await context.read<SaleProvider>().loadSales();
      if (!context.mounted) return;
      SnackBarHelper.showSuccess(context, 'Debt marked as cleared!');
    } else {
      SnackBarHelper.showError(
        context,
        'Could not clear debt. Please try again.',
      );
    }
  }

  Color _leftBorderColor() {
    if (isCleared) return AppColors.success;
    if (item.debt.amountPaid > 0) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currencyLabel;
    final debt = item.debt;
    final clientName = debt.clientName.trim();
    final clientDisplay =
        clientName.isEmpty ? 'Client not specified' : clientName;
    final clientStyle = clientName.isEmpty
        ? const TextStyle(
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: AppColors.midGrey,
          )
        : const TextStyle(
            fontSize: 13,
            color: AppColors.darkGrey,
          );

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _openDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: _leftBorderColor(), width: 4),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.itemName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 12,
                              color: AppColors.gold,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                clientDisplay,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: clientStyle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: AppColors.gold,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Since: ${Formatters.formatDate(debt.dateCreated)}',
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
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _StatusBadge(debt: debt, isCleared: isCleared),
                      const SizedBox(height: 6),
                      if (!isCleared) ...[
                        Text(
                          '${Formatters.formatCurrency(debt.balance, currency)} due',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.danger,
                          ),
                        ),
                        if (debt.amountPaid > 0) ...[
                          const SizedBox(height: 3),
                          Text(
                            'Paid: ${Formatters.formatCurrency(debt.amountPaid, currency)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Collected: '
                            '${Formatters.formatCurrency(debt.collectedRevenue, currency)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ] else ...[
                        Text(
                          'Fully paid on: '
                          '${Formatters.formatDate(debt.lastUpdated)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.midGrey,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              if (isCleared) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _openDetail(context),
                    icon: const Icon(
                      Icons.history_rounded,
                      size: 16,
                      color: AppColors.gold,
                    ),
                    label: const Text(
                      'View Payment History',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
              if (!isCleared) ...[
                const SizedBox(height: 8),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _openDetail(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.gold,
                          side: const BorderSide(color: AppColors.gold),
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text('Update Payment'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _markCleared(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.white,
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          elevation: 0,
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text('Mark Cleared'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.debt,
    required this.isCleared,
  });

  final Debt debt;
  final bool isCleared;

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late String label;

    if (isCleared) {
      bg = AppColors.success;
      label = 'CLEARED';
    } else if (debt.amountPaid == 0) {
      bg = AppColors.danger;
      label = 'UNPAID';
    } else {
      bg = AppColors.warning;
      label = 'PARTIAL';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
