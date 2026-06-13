// Shared sale form fields for add and edit screens.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../common/vynex_button.dart';
import '../common/vynex_card.dart';
import '../common/vynex_text_field.dart';

/// Shared form body for recording or editing a sale.
class SaleFormBody extends StatelessWidget {
  /// Creates the sale form body.
  const SaleFormBody({
    super.key,
    required this.formKey,
    required this.itemNameController,
    required this.quantityController,
    required this.costPriceController,
    required this.sellingPriceController,
    required this.debtNoteController,
    this.initialPaymentController,
    required this.selectedDate,
    required this.currencyLabel,
    required this.isFullyPaid,
    required this.showLossWarning,
    required this.previewRevenue,
    required this.previewCost,
    required this.previewProfitText,
    required this.previewProfitColor,
    required this.isSaving,
    required this.saveLabel,
    required this.saleType,
    required this.paymentMethod,
    required this.lockSaleType,
    required this.onSaleTypeChanged,
    required this.onPaymentMethodChanged,
    required this.onSave,
    required this.onCancel,
    required this.onUpdatePreview,
    required this.onDateSelected,
    required this.onFullyPaidChanged,
    this.contentAfterSaleType,
    this.contentBeforePayment,
    this.itemNameReadOnly = false,
    this.costPriceReadOnly = false,
    this.hideCostPrice = false,
    this.itemNameHelperText,
    this.costPriceHelperText,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController itemNameController;
  final TextEditingController quantityController;
  final TextEditingController costPriceController;
  final TextEditingController sellingPriceController;
  final TextEditingController debtNoteController;
  final TextEditingController? initialPaymentController;
  final DateTime? selectedDate;
  final String currencyLabel;
  final bool isFullyPaid;
  final bool showLossWarning;
  final String previewRevenue;
  final String previewCost;
  final String previewProfitText;
  final Color previewProfitColor;
  final bool isSaving;
  final String saveLabel;
  final String saleType;
  final String paymentMethod;
  final bool lockSaleType;
  final ValueChanged<String> onSaleTypeChanged;
  final ValueChanged<String> onPaymentMethodChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback onUpdatePreview;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<bool> onFullyPaidChanged;
  final Widget? contentAfterSaleType;
  final Widget? contentBeforePayment;
  final bool itemNameReadOnly;
  final bool costPriceReadOnly;
  final bool hideCostPrice;
  final String? itemNameHelperText;
  final String? costPriceHelperText;

  bool get _isService => saleType == 'service';

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isPastDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);
    return selected.isBefore(today);
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.gold,
              onPrimary: AppColors.black,
              surface: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = selectedDate;
    final formattedDate =
        date != null ? DateFormat('dd MMM yyyy').format(date) : null;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SaleTypeSelector(
            saleType: saleType,
            lockSaleType: lockSaleType,
            onChanged: onSaleTypeChanged,
          ),
          if (lockSaleType) ...[
            const SizedBox(height: 8),
            Text(
              'Sale type cannot be changed after recording.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.midGrey,
                    fontSize: 11,
                  ),
            ),
          ],
          if (contentAfterSaleType != null) ...[
            const SizedBox(height: 16),
            contentAfterSaleType!,
          ],
          const SizedBox(height: 16),
          VynexTextField(
            label: _isService ? 'Service Description' : 'Item Name',
            hint: _isService
                ? 'e.g. Windows Installation, Laptop Repair'
                : 'e.g. Cooking Oil 1L',
            controller: itemNameController,
            textCapitalization: TextCapitalization.words,
            readOnly: !_isService && itemNameReadOnly,
            validator: (v) => Validators.required(
              v,
              _isService ? 'Service description' : 'Item name',
            ),
          ),
          if (!_isService && itemNameHelperText != null) ...[
            const SizedBox(height: 4),
            Text(
              itemNameHelperText!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.midGrey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (!_isService) ...[
            const SizedBox(height: 16),
            VynexTextField(
              label: 'Quantity Sold',
              hint: 'e.g. 3',
              controller: quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => Validators.positiveInteger(v, 'Quantity'),
              onChanged: (_) => onUpdatePreview(),
            ),
            if (!hideCostPrice) ...[
              const SizedBox(height: 16),
              VynexTextField(
                label: 'Cost Price Per Unit',
                hint: 'What you paid for one unit e.g. 85.00',
                controller: costPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                prefixText: '$currencyLabel ',
                readOnly: costPriceReadOnly,
                validator: (v) =>
                    Validators.positiveNumber(v, 'Cost price'),
                onChanged: (_) => onUpdatePreview(),
              ),
              if (costPriceHelperText != null) ...[
                const SizedBox(height: 4),
                Text(
                  costPriceHelperText!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.midGrey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 16),
            VynexTextField(
              label: 'Selling Price Per Unit',
              hint: 'Price charged to customer e.g. 110.00',
              controller: sellingPriceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixText: '$currencyLabel ',
              validator: (v) => Validators.positiveNumber(v, 'Selling price'),
              onChanged: (_) => onUpdatePreview(),
            ),
            const SizedBox(height: 12),
            _PreviewBox(
              currencyLabel: currencyLabel,
              previewRevenue: previewRevenue,
              previewCost: previewCost,
              previewProfitText: previewProfitText,
              previewProfitColor: previewProfitColor,
              showLossWarning: showLossWarning,
            ),
          ] else ...[
            const SizedBox(height: 16),
            VynexTextField(
              label: 'Service Fee (Total)',
              hint: 'Total amount charged e.g. 350.00',
              controller: sellingPriceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixText: '$currencyLabel ',
              validator: (v) => Validators.positiveNumber(v, 'Service fee'),
              onChanged: (_) => onUpdatePreview(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold),
              ),
              child: const Text(
                'For services, the full service fee counts as both '
                'revenue and profit when payment is received.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.darkGrey,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Date of Sale',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.darkGrey,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _pickDate(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.divider,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: AppColors.gold,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      formattedDate ?? 'Select date',
                      style: TextStyle(
                        color: formattedDate == null
                            ? AppColors.midGrey
                            : AppColors.black,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.midGrey,
                  ),
                ],
              ),
            ),
          ),
          if (date != null) ...[
            const SizedBox(height: 8),
            if (_isToday(date))
              Text(
                'Recording for today',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.midGrey,
                      fontSize: 12,
                    ),
              )
            else if (_isPastDate(date))
              Text(
                'Recording for a past date: '
                '${Formatters.formatDate(DateFormat('yyyy-MM-dd').format(date))}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
              ),
          ],
          const SizedBox(height: 16),
          _PaymentMethodSelector(
            paymentMethod: paymentMethod,
            onChanged: onPaymentMethodChanged,
          ),
          if (contentBeforePayment != null) ...[
            const SizedBox(height: 16),
            contentBeforePayment!,
          ],
          const SizedBox(height: 16),
          VynexCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Is this sale fully paid?',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.midGrey,
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isFullyPaid,
                  activeTrackColor: AppColors.success,
                  onChanged: onFullyPaidChanged,
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: !isFullyPaid
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: const Border(
                          left: BorderSide(
                            color: AppColors.warning,
                            width: 4,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add a reminder note for this debt',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(height: 12),
                          VynexTextField(
                            label: 'Debt Note',
                            hint: 'e.g. John owes KES 300, will pay Friday',
                            controller: debtNoteController,
                            maxLines: 3,
                            validator: (v) {
                              if (isFullyPaid) return null;
                              if (v == null || v.trim().isEmpty) {
                                return 'Please add a note for the unpaid sale';
                              }
                              return null;
                            },
                          ),
                          if (initialPaymentController != null) ...[
                            const SizedBox(height: 12),
                            VynexTextField(
                              label: 'Initial Payment Received (Optional)',
                              hint: 'Cash received now e.g. 500.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              prefixText: '$currencyLabel ',
                              controller: initialPaymentController,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Leave empty or 0 if nothing received yet.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontSize: 11,
                                    color: AppColors.midGrey,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          VynexButton.primary(
            label: saveLabel,
            isLoading: isSaving,
            onPressed: onSave,
          ),
          const SizedBox(height: 12),
          VynexButton.secondary(
            label: 'Cancel',
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

class _SaleTypeSelector extends StatelessWidget {
  const _SaleTypeSelector({
    required this.saleType,
    required this.lockSaleType,
    required this.onChanged,
  });

  final String saleType;
  final bool lockSaleType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sale Type',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _TypePill(
                label: 'Product',
                isSelected: saleType == 'product',
                enabled: !lockSaleType,
                onTap: () => onChanged('product'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TypePill(
                label: 'Service',
                isSelected: saleType == 'service',
                enabled: !lockSaleType,
                onTap: () => onChanged('service'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({
    required this.label,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isSelected ? AppColors.black : AppColors.gold,
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodSelector extends StatelessWidget {
  const _PaymentMethodSelector({
    required this.paymentMethod,
    required this.onChanged,
  });

  final String paymentMethod;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MethodPill(
                label: 'Cash',
                value: 'cash',
                isSelected: paymentMethod == 'cash',
                onTap: () => onChanged('cash'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MethodPill(
                label: 'M-Pesa',
                value: 'mpesa',
                isSelected: paymentMethod == 'mpesa',
                onTap: () => onChanged('mpesa'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MethodPill(
                label: 'Paybill/Till',
                value: 'paybill',
                isSelected: paymentMethod == 'paybill',
                onTap: () => onChanged('paybill'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MethodPill extends StatelessWidget {
  const _MethodPill({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold, width: 1.5),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 11,
            color: isSelected ? AppColors.black : AppColors.gold,
          ),
        ),
      ),
    );
  }
}

class _PreviewBox extends StatelessWidget {
  const _PreviewBox({
    required this.currencyLabel,
    required this.previewRevenue,
    required this.previewCost,
    required this.previewProfitText,
    required this.previewProfitColor,
    required this.showLossWarning,
  });

  final String currencyLabel;
  final String previewRevenue;
  final String previewCost;
  final String previewProfitText;
  final Color previewProfitColor;
  final bool showLossWarning;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold),
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
          Text(
            'Transaction Preview',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.midGrey,
                ),
          ),
          const SizedBox(height: 8),
          _PreviewRow(
            label: 'Total Revenue',
            value: previewRevenue,
            valueColor: AppColors.gold,
          ),
          const Divider(height: 16),
          _PreviewRow(
            label: 'Total Cost',
            value: previewCost,
            valueColor: AppColors.midGrey,
          ),
          const Divider(height: 16),
          _PreviewRow(
            label: 'Profit',
            value: previewProfitText,
            valueColor: previewProfitColor,
            valueBold: true,
          ),
          if (showLossWarning) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Warning: Selling below cost price. '
                      'You will make a loss.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.valueBold = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.midGrey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: valueBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
