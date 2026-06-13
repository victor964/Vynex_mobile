// Shared purchase form fields for add and edit screens.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../common/vynex_button.dart';
import '../common/vynex_text_field.dart';

/// Shared form body for recording or editing a purchase.
class PurchaseFormBody extends StatelessWidget {
  /// Creates the purchase form body.
  const PurchaseFormBody({
    super.key,
    required this.formKey,
    required this.itemNameController,
    required this.quantityController,
    required this.costPriceController,
    required this.notesController,
    required this.selectedDate,
    required this.previewTotal,
    required this.currencyLabel,
    required this.isSaving,
    required this.saveLabel,
    required this.onSave,
    required this.onCancel,
    required this.onUpdatePreview,
    required this.onDateSelected,
    this.itemNameReadOnly = false,
    this.itemNameHelperText,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController itemNameController;
  final TextEditingController quantityController;
  final TextEditingController costPriceController;
  final TextEditingController notesController;
  final DateTime? selectedDate;
  final String previewTotal;
  final String currencyLabel;
  final bool isSaving;
  final String saveLabel;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback onUpdatePreview;
  final ValueChanged<DateTime> onDateSelected;
  final bool itemNameReadOnly;
  final String? itemNameHelperText;

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
          const _SectionHeader(label: 'Item Details'),
          const SizedBox(height: 12),
          VynexTextField(
            label: 'Item Name',
            hint: 'e.g. Maize Flour 2kg',
            controller: itemNameController,
            textCapitalization: TextCapitalization.words,
            readOnly: itemNameReadOnly,
            validator: (v) => Validators.required(v, 'Item name'),
          ),
          if (itemNameHelperText != null) ...[
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
          const SizedBox(height: 16),
          VynexTextField(
            label: 'Quantity',
            hint: 'e.g. 10',
            controller: quantityController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) => Validators.positiveInteger(v, 'Quantity'),
            onChanged: (_) => onUpdatePreview(),
          ),
          const SizedBox(height: 16),
          VynexTextField(
            label: 'Cost Price Per Unit',
            hint: 'e.g. 85.00',
            controller: costPriceController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            prefixText: '$currencyLabel ',
            validator: (v) => Validators.positiveNumber(v, 'Cost price'),
            onChanged: (_) => onUpdatePreview(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gold),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Cost:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.midGrey,
                      ),
                ),
                Text(
                  previewTotal,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionHeader(label: 'Date'),
          const SizedBox(height: 12),
          Text(
            'Date of Purchase',
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
          const _SectionHeader(label: 'Notes'),
          const SizedBox(height: 12),
          VynexTextField(
            label: 'Notes (Optional)',
            hint: 'e.g. Bought from Nairobi market',
            controller: notesController,
            maxLines: 3,
            keyboardType: TextInputType.multiline,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 2,
          width: 40,
          color: AppColors.gold,
        ),
      ],
    );
  }
}
