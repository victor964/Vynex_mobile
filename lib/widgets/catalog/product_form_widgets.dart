// Shared form section widgets for add and edit product screens.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../common/vynex_text_field.dart';

/// Gold section label with underline.
class ProductFormSectionLabel extends StatelessWidget {
  const ProductFormSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.goldOnLight,
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 1,
          width: 40,
          color: AppColors.goldOnLight,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// Tappable category selector field.
class CategoryPickerField extends StatelessWidget {
  const CategoryPickerField({
    super.key,
    required this.selectedName,
    required this.onTap,
  });

  final String? selectedName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasSelection =
        selectedName != null && selectedName!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.midGrey),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.category_rounded,
              color: AppColors.goldOnLight,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasSelection
                    ? selectedName!
                    : 'Select Category (Optional)',
                style: TextStyle(
                  color: hasSelection
                      ? AppColors.black
                      : AppColors.midGrey,
                  fontSize: 14,
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
    );
  }
}

/// Tappable unit selector field.
class UnitPickerField extends StatelessWidget {
  const UnitPickerField({
    super.key,
    required this.selectedUnit,
    required this.onTap,
  });

  final String selectedUnit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.midGrey),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.straighten_rounded,
              color: AppColors.goldOnLight,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selectedUnit,
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 14,
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
    );
  }
}

/// Live profit preview box for product pricing.
class ProductProfitPreview extends StatelessWidget {
  const ProductProfitPreview({
    super.key,
    required this.profitText,
    required this.isPositive,
  });

  final String profitText;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold),
      ),
      child: Text(
        'Default Profit: $profitText',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isPositive ? AppColors.success : AppColors.danger,
        ),
      ),
    );
  }
}

/// Barcode field with optional scan button callback.
class BarcodeField extends StatelessWidget {
  const BarcodeField({
    super.key,
    required this.controller,
    this.onScan,
  });

  final TextEditingController controller;
  final VoidCallback? onScan;

  @override
  Widget build(BuildContext context) {
    return VynexTextField(
      label: 'Barcode (Optional)',
      hint: 'Scan or type barcode number',
      keyboardType: TextInputType.text,
      controller: controller,
      suffixIcon: IconButton(
        onPressed: onScan,
        icon: const Icon(
          Icons.qr_code_scanner_rounded,
          color: AppColors.goldOnLight,
        ),
        tooltip: 'Scan barcode',
      ),
    );
  }
}

/// Shows unit picker bottom sheet, returns selected unit string.
Future<String?> showUnitPickerSheet(
  BuildContext context, {
  required String currentUnit,
}) async {
  const units = [
    'piece',
    'pack',
    'box',
    'kg',
    'gram',
    'litre',
    'metre',
    'pair',
    'dozen',
    'set',
  ];

  return showModalBottomSheet<String>(
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
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Unit',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            ...units.map((unit) {
              return ListTile(
                title: Text(unit),
                trailing: unit == currentUnit
                    ? const Icon(Icons.check, color: AppColors.goldOnLight)
                    : null,
                onTap: () => Navigator.pop(sheetContext, unit),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

/// Small grey helper note below a field.
class FieldNote extends StatelessWidget {
  const FieldNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.midGrey,
          fontSize: 11,
        ),
      ),
    );
  }
}

/// Info box with gold icon.
class ProductInfoBox extends StatelessWidget {
  const ProductInfoBox({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.goldOnLight, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.midGrey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Builds profit preview text from cost and selling controllers.
String buildProfitPreviewText(
  BuildContext context,
  TextEditingController costController,
  TextEditingController sellingController,
) {
  final currency = context.read<SettingsProvider>().currencyLabel;
  final cost = double.tryParse(costController.text.trim()) ?? 0;
  final selling = double.tryParse(sellingController.text.trim()) ?? 0;
  final profit = selling - cost;
  return '$currency ${profit.toStringAsFixed(2)}';
}

bool isProfitPositive(
  TextEditingController costController,
  TextEditingController sellingController,
) {
  final cost = double.tryParse(costController.text.trim()) ?? 0;
  final selling = double.tryParse(sellingController.text.trim()) ?? 0;
  return selling - cost >= 0;
}
