// customer_history_item.dart
// Shows a single sale in the customer purchase history.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/sale.dart';
import '../../providers/settings_provider.dart';

class CustomerHistoryItem extends StatelessWidget {
  const CustomerHistoryItem({
    super.key,
    required this.sale,
    required this.isLast,
    this.hasLinkedDebt = false,
  });

  final Sale sale;
  final bool isLast;
  final bool hasLinkedDebt;

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currencyLabel;
    final dotColor = sale.isFullyPaid
        ? AppColors.success
        : AppColors.danger;

    String statusLabel;
    Color statusColor;
    if (sale.isFullyPaid) {
      statusLabel = 'PAID';
      statusColor = AppColors.success;
    } else if (hasLinkedDebt) {
      statusLabel = 'PARTIAL';
      statusColor = AppColors.warning;
    } else {
      statusLabel = 'UNPAID';
      statusColor = AppColors.danger;
    }

    return InkWell(
      onTap: () => context.push('/sales/detail/${sale.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 42,
                    color: AppColors.lightGrey,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          sale.itemName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      Text(
                        sale.isFullyPaid
                            ? Formatters.formatCurrency(
                                sale.totalRevenue,
                                currency,
                              )
                            : 'KES 0 - Unpaid',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: sale.isFullyPaid
                              ? AppColors.gold
                              : AppColors.midGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        Formatters.formatDate(sale.dateSold),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.midGrey,
                        ),
                      ),
                      const Spacer(),
                      _PaymentPill(method: sale.paymentMethod),
                      const Spacer(),
                      _StatusPill(
                        label: statusLabel,
                        color: statusColor,
                      ),
                    ],
                  ),
                  if (sale.saleSource != 'manual') ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        sale.saleSourceLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  if (!isLast)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Divider(height: 1, color: AppColors.divider),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentPill extends StatelessWidget {
  const _PaymentPill({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (method) {
      case 'mpesa':
        color = AppColors.success;
        label = 'M-Pesa';
      case 'paybill':
        color = AppColors.info;
        label = 'Paybill';
      default:
        color = AppColors.midGrey;
        label = 'Cash';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
      ),
    );
  }
}
