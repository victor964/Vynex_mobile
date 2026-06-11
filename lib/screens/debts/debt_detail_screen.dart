// Debt detail screen with sale info, status, and payment updates.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/debug_log.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/database/database_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/debt.dart';
import '../../models/sale.dart';
import '../../providers/debt_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/vynex_app_bar.dart';
import '../../widgets/common/vynex_button.dart';
import '../../widgets/common/vynex_card.dart';
import '../../widgets/common/vynex_text_field.dart';

/// Detail screen for a single debt with payment form.
class DebtDetailScreen extends StatefulWidget {
  /// Creates the debt detail screen.
  const DebtDetailScreen({super.key, required this.debtId});

  final int debtId;

  @override
  State<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _amountPaidController = TextEditingController();

  Debt? _debt;
  Sale? _sale;
  bool _isLoading = true;
  bool _isUpdating = false;
  double _previewBalance = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final db = DatabaseHelper();
      final debt = await db.getDebtById(widget.debtId);
      Sale? sale;
      if (debt != null) {
        sale = await db.getSaleById(debt.saleId);
      }
      if (!mounted) return;
      setState(() {
        _debt = debt;
        _sale = sale;
        _isLoading = false;
      });
      if (debt != null) {
        _clientNameController.text = debt.clientName;
        _amountPaidController.text = '';
        _updatePreviewBalance();
      }
    } catch (e) {
      logDebug('Debt detail load error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(
          context,
          'Could not load debt details.',
        );
      }
    }
  }

  void _updatePreviewBalance() {
    final debt = _debt;
    if (debt == null) return;
    final todayAmt = double.tryParse(_amountPaidController.text) ?? 0.0;
    final newBalance = debt.amountOwed - (debt.amountPaid + todayAmt);
    setState(() {
      _previewBalance = newBalance < 0 ? 0.0 : newBalance;
    });
  }

  Future<void> _updatePayment() async {
    final debt = _debt;
    if (debt == null || !_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    final todayAmount = double.parse(_amountPaidController.text.trim());
    final success = await context.read<DebtProvider>().updateDebtPayment(
          debtId: debt.id!,
          clientName: _clientNameController.text.trim(),
          todayAmount: todayAmount,
        );

    if (!mounted) return;

    setState(() => _isUpdating = false);

    if (!success) {
      SnackBarHelper.showError(
        context,
        'Could not update payment. Please try again.',
      );
      return;
    }

    await context.read<SaleProvider>().loadSales();
    await _loadData();
    if (!mounted) return;

    final refreshed = _debt;
    final currency = context.read<SettingsProvider>().currencyLabel;
    HapticFeedback.lightImpact();
    if (refreshed != null && refreshed.isCleared) {
      SnackBarHelper.showSuccess(
        context,
        'Debt fully cleared! Total collected: '
        '${Formatters.formatCurrency(refreshed.amountOwed, currency)}',
      );
    } else if (refreshed != null) {
      SnackBarHelper.showSuccess(
        context,
        'Payment of ${Formatters.formatCurrency(todayAmount, currency)} '
        'recorded. Balance remaining: '
        '${Formatters.formatCurrency(refreshed.balance, currency)}',
      );
    }
  }

  Future<void> _markCleared() async {
    final debt = _debt;
    if (debt == null) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Mark as Cleared',
      message:
          'Mark this debt as fully paid? This will set the balance to zero.',
      confirmLabel: 'Yes, Clear It',
    );
    if (!confirmed || !mounted) return;

    final success =
        await context.read<DebtProvider>().markDebtCleared(debt.id!);
    if (!mounted) return;

    if (!success) {
      SnackBarHelper.showError(
        context,
        'Could not clear debt. Please try again.',
      );
      return;
    }

    await context.read<SaleProvider>().loadSales();
    await _loadData();
    if (!mounted) return;

    HapticFeedback.lightImpact();
    SnackBarHelper.showSuccess(context, 'Debt marked as cleared!');
  }

  Color _profitColor(double profit) {
    if (profit > 0) return AppColors.success;
    if (profit < 0) return AppColors.danger;
    return AppColors.midGrey;
  }

  Color _statusBorderColor(Debt debt) {
    if (debt.isCleared) return AppColors.success;
    if (debt.amountPaid > 0) return AppColors.warning;
    return AppColors.danger;
  }

  String _statusLabel(Debt debt) {
    if (debt.isCleared) return 'CLEARED';
    if (debt.amountPaid > 0) return 'PARTIAL';
    return 'UNPAID';
  }

  Color _statusBadgeColor(Debt debt) {
    if (debt.isCleared) return AppColors.success;
    if (debt.amountPaid > 0) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currencyLabel;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: VynexAppBar(
          title: 'Debt Details',
          showBack: true,
        ),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    final debt = _debt;
    final sale = _sale;
    if (debt == null || sale == null) {
      return const Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: VynexAppBar(
          title: 'Debt Details',
          showBack: true,
        ),
        body: Center(child: Text('Debt not found')),
      );
    }

    final isCleared = debt.isCleared;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: const VynexAppBar(
        title: 'Debt Details',
        showBack: true,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: isCleared
              ? VynexButton.secondary(
                  label: 'Back to Debts',
                  onPressed: () => context.pop(),
                )
              : OutlinedButton.icon(
                  onPressed: _markCleared,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark as Fully Cleared'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                          'Related Sale',
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
                      label: 'Item Name',
                      value: sale.itemName,
                      valueBold: true,
                    ),
                    const _ThinDivider(),
                    _InfoRow(
                      label: 'Date Sold',
                      value: Formatters.formatDate(sale.dateSold),
                    ),
                    const _ThinDivider(),
                    _InfoRow(
                      label: 'Quantity',
                      value: '${sale.quantitySold}',
                    ),
                    const _ThinDivider(),
                    _InfoRow(
                      label: 'Selling Price',
                      value: Formatters.formatCurrency(
                        sale.sellingPrice,
                        currency,
                      ),
                    ),
                    const _ThinDivider(),
                    _InfoRow(
                      label: 'Total Revenue',
                      value: sale.isFullyPaid
                          ? Formatters.formatCurrency(
                              sale.totalRevenue,
                              currency,
                            )
                          : Formatters.formatCurrency(
                              debt.collectedRevenue,
                              currency,
                            ),
                      valueColor: AppColors.gold,
                      valueBold: true,
                    ),
                    const _ThinDivider(),
                    _InfoRow(
                      label: 'Profit',
                      value: sale.isFullyPaid
                          ? Formatters.formatCurrency(
                              sale.profit,
                              currency,
                            )
                          : 'Pending (${Formatters.formatCurrency(
                              sale.potentialProfit,
                              currency,
                            )} potential)',
                      valueColor: sale.isFullyPaid
                          ? _profitColor(sale.profit)
                          : AppColors.warning,
                      valueBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _statusBorderColor(debt),
                    width: 2,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          color: AppColors.gold,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Debt Status',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusBadgeColor(debt),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusLabel(debt),
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'Client Name',
                      value: debt.clientName.trim().isEmpty
                          ? 'Not specified'
                          : debt.clientName,
                      valueItalic: debt.clientName.trim().isEmpty,
                      valueColor: debt.clientName.trim().isEmpty
                          ? AppColors.midGrey
                          : AppColors.black,
                    ),
                    const _ThinDivider(),
                    _InfoRow(
                      label: 'Amount Owed',
                      value: Formatters.formatCurrency(
                        debt.amountOwed,
                        currency,
                      ),
                      valueColor: AppColors.danger,
                      valueBold: true,
                    ),
                    const _ThinDivider(),
                    _InfoRow(
                      label: 'Amount Paid',
                      value: Formatters.formatCurrency(
                        debt.amountPaid,
                        currency,
                      ),
                      valueColor: AppColors.success,
                      valueBold: true,
                    ),
                    const _ThinDivider(),
                    _InfoRow(
                      label: 'Balance Remaining',
                      value: Formatters.formatCurrency(
                        debt.balance,
                        currency,
                      ),
                      valueColor: AppColors.danger,
                      valueBold: true,
                      valueSize: 18,
                    ),
                    const _ThinDivider(),
                    _InfoRow(
                      label: 'Date Created',
                      value: Formatters.formatDate(debt.dateCreated),
                    ),
                    const _ThinDivider(),
                    _InfoRow(
                      label: 'Last Updated',
                      value: Formatters.formatDate(debt.lastUpdated),
                    ),
                    if (sale.debtNote != null &&
                        sale.debtNote!.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.gold),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.bookmark,
                                  size: 16,
                                  color: AppColors.gold,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Your Note',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.midGrey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              sale.debtNote!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: AppColors.darkGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (debt.parsedPaymentHistory.isNotEmpty) ...[
                const SizedBox(height: 12),
                _PaymentHistoryTimeline(
                  debt: debt,
                  currency: currency,
                ),
              ],
              if (!isCleared) ...[
                const SizedBox(height: 12),
                VynexCard(
                  hasAccent: true,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.edit, color: AppColors.gold, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Record Payment',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.gold),
                          ),
                          child: const Text(
                            'Enter only the amount received in this '
                            'payment. Previous payments are added '
                            'automatically.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.darkGrey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        VynexTextField(
                          label: 'Client Name',
                          hint: 'e.g. John Kamau',
                          controller: _clientNameController,
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 12),
                        VynexTextField(
                          label: 'Amount Received Today',
                          hint: 'e.g. 150.00',
                          controller: _amountPaidController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          prefixText: '$currency ',
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          onChanged: (_) => _updatePreviewBalance(),
                          validator: (value) {
                            final today = double.tryParse(value ?? '');
                            if (today == null || today < 0) {
                              return 'Enter a valid amount';
                            }
                            if (today == 0) {
                              return 'Enter an amount greater than zero';
                            }
                            final newTotal = debt.amountPaid + today;
                            if (newTotal > debt.amountOwed) {
                              final maxToday =
                                  debt.amountOwed - debt.amountPaid;
                              return 'Maximum you can receive today is '
                                  '$currency ${maxToday.toStringAsFixed(2)}';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Already collected: '
                          '${Formatters.formatCurrency(debt.amountPaid, currency)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.midGrey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'After this payment: '
                          '${Formatters.formatCurrency(
                            debt.amountPaid +
                                (double.tryParse(
                                      _amountPaidController.text,
                                    ) ??
                                    0.0),
                            currency,
                          )}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Remaining balance: '
                          '${Formatters.formatCurrency(
                            _previewBalance,
                            currency,
                          )}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _previewBalance == 0
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        ),
                        const SizedBox(height: 16),
                        VynexButton.primary(
                          label: 'Update Payment',
                          isLoading: _isUpdating,
                          onPressed: _updatePayment,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentHistoryTimeline extends StatelessWidget {
  const _PaymentHistoryTimeline({
    required this.debt,
    required this.currency,
  });

  final Debt debt;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final history = debt.parsedPaymentHistory;
    return VynexCard(
      hasAccent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded, color: AppColors.gold, size: 20),
              SizedBox(width: 8),
              Text(
                'Payment History',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...history.asMap().entries.map((entry) {
            final idx = entry.key;
            final p = entry.value;
            final amount = (p['amount'] as num).toDouble();
            final date = p['date'] as String;
            final balance = (p['balance'] as num).toDouble();
            final isLast = idx == history.length - 1;
            final cleared = balance <= 0 && isLast && debt.isCleared;

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
                              '+${Formatters.formatCurrency(amount, currency)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              cleared
                                  ? 'Fully Cleared'
                                  : balance <= 0
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
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueBold = false,
    this.valueItalic = false,
    this.valueColor,
    this.valueSize = 13,
  });

  final String label;
  final String value;
  final bool valueBold;
  final bool valueItalic;
  final Color? valueColor;
  final double valueSize;

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
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: valueSize,
              color: valueColor ?? AppColors.black,
              fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
              fontStyle: valueItalic ? FontStyle.italic : FontStyle.normal,
            ),
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
