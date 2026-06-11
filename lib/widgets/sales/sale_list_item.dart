// Full list item card for a single sale record.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/debt.dart';
import '../../models/sale.dart';
import '../../providers/debt_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/settings_provider.dart';
import '../common/confirm_dialog.dart';

/// List item card for one sale with edit and delete actions.
class SaleListItem extends StatelessWidget {
  /// Creates a sale list item.
  const SaleListItem({
    super.key,
    required this.sale,
    this.debt,
    this.paidByInstallments = false,
  });

  final Sale sale;
  final Debt? debt;
  final bool paidByInstallments;

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
                  context.push('/sales/edit/${sale.id}');
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
      title: 'Delete Sale',
      message: "Delete '${sale.itemName}'? This cannot be undone.",
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final success = await context.read<SaleProvider>().deleteSale(
          sale.id!,
        );
    if (!context.mounted) return;

    if (success) {
      SnackBarHelper.showSuccess(context, 'Sale deleted');
      await context.read<DebtProvider>().loadDebts();
    } else {
      SnackBarHelper.showError(
        context,
        'Failed to delete sale. Please try again.',
      );
    }
  }

  Color _leftBorderColor() {
    if (sale.isFullyPaid) return AppColors.success;
    if (debt != null && debt!.isCleared) return AppColors.success;
    return AppColors.danger;
  }

  Widget _buildStatusBadge() {
    if (sale.isFullyPaid) {
      return _pill('PAID', AppColors.success);
    }
    if (debt == null) {
      return _pill('UNPAID', AppColors.danger);
    }
    if (debt!.isCleared) {
      return _pill('DEBT PAID', AppColors.success);
    }
    if (debt!.amountPaid > 0) {
      return _pill('PARTIAL', AppColors.warning);
    }
    return _pill('UNPAID', AppColors.danger);
  }

  Widget _pill(String label, Color color, {Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? AppColors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _paymentMethodPill() {
    switch (sale.paymentMethod) {
      case 'mpesa':
        return _pill(
          'M-Pesa',
          AppColors.success.withValues(alpha: 0.15),
          textColor: AppColors.success,
        );
      case 'paybill':
        return _pill(
          'Paybill',
          AppColors.info.withValues(alpha: 0.12),
          textColor: AppColors.info,
        );
      default:
        return _pill(
          'Cash',
          AppColors.lightGrey,
          textColor: AppColors.darkGrey,
        );
    }
  }

  IconData _paymentIcon() {
    switch (sale.paymentMethod) {
      case 'mpesa':
        return Icons.phone_android;
      case 'paybill':
        return Icons.account_balance;
      default:
        return Icons.payments;
    }
  }

  String _profitLabel(String currency) {
    if (!sale.isFullyPaid) {
      return 'Pending';
    }
    if (sale.profit > 0) {
      return '+${Formatters.formatCurrency(sale.profit, currency)}';
    }
    if (sale.profit == 0) {
      return Formatters.formatCurrency(0, currency);
    }
    return '-${Formatters.formatCurrency(sale.profit.abs(), currency)}';
  }

  Color _profitColor() {
    if (!sale.isFullyPaid) return AppColors.warning;
    if (sale.profit > 0) return AppColors.success;
    if (sale.profit < 0) return AppColors.danger;
    return AppColors.midGrey;
  }

  String _revenueLabel(String currency) {
    if (sale.isFullyPaid) {
      return Formatters.formatCurrency(sale.totalRevenue, currency);
    }
    final collected = debt?.collectedRevenue ?? 0.0;
    return Formatters.formatCurrency(collected, currency);
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currencyLabel;

    return GestureDetector(
      onTap: () => context.push('/sales/detail/${sale.id}'),
      onLongPress: () => _showOptions(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: _leftBorderColor(),
              width: 4,
            ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sale.itemName,
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
                        size: 12,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        Formatters.formatDate(sale.dateSold),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.midGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _paymentIcon(),
                        size: 12,
                        color: sale.paymentMethod == 'mpesa'
                            ? AppColors.success
                            : sale.paymentMethod == 'paybill'
                                ? AppColors.info
                                : AppColors.midGrey,
                      ),
                      const SizedBox(width: 4),
                      _paymentMethodPill(),
                      if (sale.isService) ...[
                        const SizedBox(width: 6),
                        _pill(
                          'Service',
                          AppColors.teal.withValues(alpha: 0.15),
                          textColor: AppColors.teal,
                        ),
                      ],
                    ],
                  ),
                  if (!sale.isService) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Qty: ${sale.quantitySold}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.midGrey,
                      ),
                    ),
                  ],
                  if (!sale.isFullyPaid &&
                      sale.debtNote != null &&
                      sale.debtNote!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 12,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            sale.debtNote!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.warning,
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
                _buildStatusBadge(),
                if (sale.isFullyPaid && paidByInstallments) ...[
                  const SizedBox(height: 4),
                  _pill(
                    'Installments',
                    AppColors.purple.withValues(alpha: 0.15),
                    textColor: AppColors.purple,
                  ),
                ],
                if (debt != null &&
                    debt!.amountPaid > 0 &&
                    !debt!.isCleared) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Collected: ${Formatters.formatCurrency(
                      debt!.collectedRevenue,
                      currency,
                    )}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.success,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _profitLabel(currency),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _profitColor(),
                    fontStyle:
                        sale.isFullyPaid ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sale.isFullyPaid
                      ? 'Rev: ${_revenueLabel(currency)}'
                      : 'Coll: ${_revenueLabel(currency)}',
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
