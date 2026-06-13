// Sale detail screen showing sale info and linked debt.

import 'package:flutter/material.dart';
import '../../core/utils/debug_log.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/database/database_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/customer.dart';
import '../../models/debt.dart';
import '../../models/sale.dart';
import '../../providers/debt_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/vynex_app_bar.dart';
import '../../widgets/common/vynex_button.dart';
import '../../widgets/common/vynex_card.dart';

/// Detail screen for a single sale record.
class SaleDetailScreen extends StatefulWidget {
  /// Creates the sale detail screen.
  const SaleDetailScreen({super.key, required this.saleId});

  final int saleId;

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  Sale? _sale;
  Debt? _debt;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      final db = DatabaseHelper();
      final sale = await db.getSaleById(widget.saleId);
      Debt? debt;
      if (sale != null) {
        debt = await db.getDebtBySaleId(widget.saleId);
      }
      if (mounted) {
        setState(() {
          _sale = sale;
          _debt = debt;
          _isLoading = false;
        });
      }
    } catch (e) {
      logDebug('Sale detail load error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(
          context,
          'Could not load sale details.',
        );
      }
    }
  }

  Future<void> _deleteSale() async {
    final sale = _sale;
    if (sale == null) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Sale',
      message: "Delete '${sale.itemName}'? This cannot be undone.",
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    final success =
        await context.read<SaleProvider>().deleteSale(widget.saleId);
    if (!mounted) return;

    if (!mounted) return;

    if (success) {
      await context.read<DebtProvider>().loadDebts();
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Sale deleted');
      Navigator.pop(context);
    } else {
      SnackBarHelper.showError(
        context,
        'Failed to delete sale. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currencyLabel;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: VynexAppBar(
          title: 'Sale Details',
          showBack: true,
        ),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    final sale = _sale;
    final debt = _debt;
    final paidByInstallments =
        sale != null && debt != null && debt.isCleared && sale.isFullyPaid;

    if (sale == null) {
      return const Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: VynexAppBar(
          title: 'Sale Details',
          showBack: true,
        ),
        body: Center(
          child: Text('Sale not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: VynexAppBar(
        title: 'Sale Details',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.gold),
            onPressed: () => context.push('/sales/edit/${sale.id}'),
          ),
        ],
      ),
      bottomNavigationBar: _sale == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  8,
                  12,
                  12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push(
                          '/sales/edit/${widget.saleId}',
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.gold,
                            width: 2,
                          ),
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Edit',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push(
                          '/invoice/${widget.saleId}',
                        ),
                        icon: const Icon(
                          Icons.receipt_long_rounded,
                          size: 16,
                          color: AppColors.black,
                        ),
                        label: const Text(
                          'Invoice',
                          style: TextStyle(
                            color: AppColors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _deleteSale,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VynexCard(
                hasAccent: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          color: AppColors.gold,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Sale Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: sale.isService ? 'Service' : 'Item Name',
                      value: sale.itemName,
                      valueBold: true,
                    ),
                    const _ThinDivider(),
                    _InfoRow(
                      label: 'Sale Type',
                      value: sale.isService ? 'Service' : 'Product',
                    ),
                    const _ThinDivider(),
                    _InfoRow(
                      label: 'Sale Source',
                      value: sale.saleSourceLabel,
                      valueColor: _sourceColor(sale.saleSource),
                    ),
                    if (sale.isFromStock && sale.productId != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Text(
                              'Catalog Product',
                              style: TextStyle(
                                color: AppColors.midGrey,
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => context.push(
                                '/catalog/detail/${sale.productId}',
                              ),
                              child: const Text(
                                'View Product',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const _ThinDivider(),
                    _InfoRow(
                      label: 'Payment Method',
                      value: sale.paymentMethodLabel,
                      leadingIcon: _paymentIcon(sale.paymentMethod),
                    ),
                    if (sale.customerId != null)
                      FutureBuilder<Customer?>(
                        future: DatabaseHelper()
                            .getCustomerById(sale.customerId!),
                        builder: (context, snapshot) {
                          final customer = snapshot.data;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                const Text(
                                  'Customer',
                                  style: TextStyle(
                                    color: AppColors.midGrey,
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                if (customer != null)
                                  GestureDetector(
                                    onTap: () => context.push(
                                      '/customers/detail/'
                                      '${customer.id}',
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          customer.name,
                                          style: const TextStyle(
                                            color: AppColors.gold,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.open_in_new_rounded,
                                          color: AppColors.gold,
                                          size: 14,
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  const Text(
                                    'Loading...',
                                    style: TextStyle(
                                      color: AppColors.midGrey,
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    const _ThinDivider(),
                    _InfoRow(
                      label: 'Date',
                      value: Formatters.formatDate(sale.dateSold),
                    ),
                    if (!sale.isService) ...[
                      const _ThinDivider(),
                      _InfoRow(
                        label: 'Quantity Sold',
                        value: '${sale.quantitySold}',
                      ),
                      const _ThinDivider(),
                      _InfoRow(
                        label: 'Cost Per Unit',
                        value: Formatters.formatCurrency(
                          sale.costPrice,
                          currency,
                        ),
                      ),
                      if (sale.isSpotBuy && sale.spotCost != null) ...[
                        const _ThinDivider(),
                        _InfoRow(
                          label: 'Spot Cost Paid',
                          value: Formatters.formatCurrency(
                            sale.spotCost!,
                            currency,
                          ),
                          valueColor: AppColors.danger,
                        ),
                      ],
                    ],
                    const _ThinDivider(),
                    _InfoRow(
                      label: sale.isService ? 'Service Fee' : 'Selling Price',
                      value: Formatters.formatCurrency(
                        sale.sellingPrice,
                        currency,
                      ),
                    ),
                    const _ThinDivider(),
                    _RevenueRow(
                      sale: sale,
                      debt: _debt,
                      currency: currency,
                    ),
                    const _ThinDivider(),
                    _ProfitRow(
                      sale: sale,
                      currency: currency,
                    ),
                    const _ThinDivider(),
                    Row(
                      children: [
                        const Expanded(
                          flex: 1,
                          child: Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.midGrey,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _PaidBadge(isPaid: sale.isFullyPaid),
                          ),
                        ),
                      ],
                    ),
                    const _ThinDivider(),
                    _PaymentHistoryRow(
                      paidByInstallments: paidByInstallments,
                      debtId: debt?.id,
                    ),
                  ],
                ),
              ),
              if (!sale.isFullyPaid) ...[
                const SizedBox(height: 12),
                _DebtSection(
                  sale: sale,
                  debt: _debt,
                  currency: currency,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RevenueRow extends StatelessWidget {
  const _RevenueRow({
    required this.sale,
    required this.debt,
    required this.currency,
  });

  final Sale sale;
  final Debt? debt;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          flex: 1,
          child: Text(
            'Total Revenue',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.midGrey,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: sale.isFullyPaid
              ? Text(
                  Formatters.formatCurrency(
                    sale.totalRevenue,
                    currency,
                  ),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.formatCurrency(
                        debt?.collectedRevenue ?? 0.0,
                        currency,
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                    ),
                    const Text(
                      'Collected so far',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.midGrey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ProfitRow extends StatelessWidget {
  const _ProfitRow({
    required this.sale,
    required this.currency,
  });

  final Sale sale;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          flex: 1,
          child: Text(
            'Profit',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.midGrey,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: sale.isFullyPaid
              ? Text(
                  Formatters.formatCurrency(sale.profit, currency),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color:
                        sale.profit >= 0 ? AppColors.success : AppColors.danger,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Pending',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    Text(
                      'Potential: ${Formatters.formatCurrency(
                        sale.potentialProfit,
                        currency,
                      )}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.midGrey,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

Color _sourceColor(String source) {
  switch (source) {
    case 'stock':
      return AppColors.success;
    case 'spot_buy':
      return AppColors.warning;
    case 'service':
      return AppColors.purple;
    default:
      return AppColors.midGrey;
  }
}

IconData _paymentIcon(String method) {
  switch (method) {
    case 'mpesa':
      return Icons.phone_android;
    case 'paybill':
      return Icons.account_balance;
    default:
      return Icons.payments;
  }
}

class _PaymentHistoryRow extends StatelessWidget {
  const _PaymentHistoryRow({
    required this.paidByInstallments,
    this.debtId,
  });

  final bool paidByInstallments;
  final int? debtId;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          flex: 1,
          child: Text(
            'Payment History',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.midGrey,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: paidByInstallments && debtId != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 14,
                          color: AppColors.purple,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Paid via installments',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: () =>
                          context.push('/debt/detail/$debtId'),
                      icon: const Icon(
                        Icons.history_rounded,
                        size: 14,
                        color: AppColors.gold,
                      ),
                      label: const Text(
                        'View Payment History',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.gold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                )
              : const Text(
                  'Paid in full at time of sale',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.midGrey,
                  ),
                ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueBold = false,
    this.valueColor,
    this.leadingIcon,
  });

  final String label;
  final String value;
  final bool valueBold;
  final Color? valueColor;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.midGrey,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 14, color: AppColors.gold),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    color: valueColor ?? AppColors.black,
                    fontWeight:
                        valueBold ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThinDivider extends StatelessWidget {
  const _ThinDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Divider(height: 1, color: AppColors.divider),
    );
  }
}

class _PaidBadge extends StatelessWidget {
  const _PaidBadge({required this.isPaid});

  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    final bg = isPaid ? AppColors.success : AppColors.danger;
    final label = isPaid ? 'Paid' : 'Unpaid';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DebtSection extends StatelessWidget {
  const _DebtSection({
    required this.sale,
    required this.debt,
    required this.currency,
  });

  final Sale sale;
  final Debt? debt;
  final String currency;

  Widget _buildDebtStatusBadge(Debt debt) {
    if (debt.isCleared) {
      return _badge('DEBT FULLY PAID', AppColors.success);
    }
    if (debt.amountPaid > 0) {
      return _badge('PARTIAL', AppColors.warning);
    }
    return _badge('UNPAID', AppColors.danger);
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppColors.danger, width: 4),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Debt Information',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (debt == null)
            const Text(
              'No debt record found for this sale.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: AppColors.midGrey,
              ),
            )
          else ...[
            _InfoRow(
              label: 'Client Name',
              value: debt!.clientName.trim().isEmpty
                  ? 'Not specified'
                  : debt!.clientName,
            ),
            const _ThinDivider(),
            _InfoRow(
              label: 'Amount Owed',
              value: Formatters.formatCurrency(
                debt!.amountOwed,
                currency,
              ),
              valueColor: AppColors.danger,
            ),
            const _ThinDivider(),
            _InfoRow(
              label: 'Amount Paid',
              value: Formatters.formatCurrency(
                debt!.amountPaid,
                currency,
              ),
              valueColor: AppColors.success,
            ),
            const _ThinDivider(),
            _InfoRow(
              label: 'Balance',
              value: Formatters.formatCurrency(
                debt!.balance,
                currency,
              ),
              valueColor: AppColors.danger,
              valueBold: true,
            ),
            const _ThinDivider(),
            Row(
              children: [
                const Expanded(
                  flex: 1,
                  child: Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.midGrey,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _buildDebtStatusBadge(debt!),
                  ),
                ),
              ],
            ),
            if (sale.debtNote != null && sale.debtNote!.trim().isNotEmpty) ...[
              const _ThinDivider(),
              const Row(
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Your Note:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                sale.debtNote!,
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: AppColors.warning,
                ),
              ),
            ],
            if (debt!.parsedPaymentHistory.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    color: AppColors.gold,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Payment History',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...debt!.parsedPaymentHistory.asMap().entries.map((entry) {
                final idx = entry.key;
                final p = entry.value;
                final amount = (p['amount'] as num).toDouble();
                final date = p['date'] as String;
                final balance = (p['balance'] as num).toDouble();
                final isLast = idx == debt!.parsedPaymentHistory.length - 1;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: balance <= 0
                                  ? AppColors.success
                                  : AppColors.gold,
                              border: Border.all(
                                color: AppColors.white,
                                width: 2,
                              ),
                            ),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 28,
                              color: AppColors.lightGrey,
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payment ${idx + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  Formatters.formatDate(date),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.midGrey,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '+${Formatters.formatCurrency(
                                    amount,
                                    currency,
                                  )}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppColors.success,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  balance <= 0
                                      ? 'Cleared'
                                      : 'Bal: ${Formatters.formatCurrency(
                                          balance,
                                          currency,
                                        )}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: balance <= 0
                                        ? AppColors.success
                                        : AppColors.danger,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 12),
            VynexButton.primary(
              label: 'Update Debt Payment',
              onPressed: () {
                context.push('/debt/detail/${debt!.id}');
              },
            ),
          ],
        ],
      ),
    );
  }
}
