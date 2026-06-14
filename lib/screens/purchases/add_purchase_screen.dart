// Add purchase screen with form validation and date backdating.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/product.dart';
import '../../models/purchase.dart';
import '../../providers/product_provider.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/catalog/product_picker_sheet.dart';
import '../../widgets/catalog/stock_badge_widget.dart';
import '../../widgets/common/vynex_app_bar.dart';
import '../../widgets/purchases/purchase_form_body.dart';

/// Form screen for recording a new purchase.
class AddPurchaseScreen extends StatefulWidget {
  /// Creates the add purchase screen.
  const AddPurchaseScreen({super.key});

  @override
  State<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  String _purchaseType = 'general';
  Product? _selectedProduct;
  String _previewTotal = 'KES 0.00';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadSettings();
      _updatePreview();
    });
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    _costPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updatePreview() {
    final currency = context.read<SettingsProvider>().currencyLabel;
    final qty = int.tryParse(_quantityController.text.trim());
    final cost = double.tryParse(_costPriceController.text.trim());
    if (qty != null && qty > 0 && cost != null && cost > 0) {
      setState(() {
        _previewTotal = Formatters.formatCurrency(
          qty * cost,
          currency,
        );
      });
    } else {
      setState(() {
        _previewTotal = Formatters.formatCurrency(0, currency);
      });
    }
  }

  Future<void> _pickProduct() async {
    final product = await ProductPickerSheet.show(context);
    if (product == null || !mounted) return;

    setState(() {
      _selectedProduct = product;
      _itemNameController.text = product.name;
      _costPriceController.text =
          product.defaultCostPrice.toStringAsFixed(2);
    });
    _updatePreview();
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.goldOnLight,
        fontWeight: FontWeight.bold,
        fontSize: 11,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildPurchaseTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel('PURCHASE TYPE'),
        const SizedBox(height: 8),
        _typeCard(
          type: 'restock',
          icon: Icons.inventory_2_rounded,
          title: 'Restock',
          subtitle: 'Add stock for an existing catalog product',
          color: AppColors.success,
        ),
        const SizedBox(height: 8),
        _typeCard(
          type: 'general',
          icon: Icons.receipt_long_rounded,
          title: 'General',
          subtitle: 'Record a purchase without catalog (classic)',
          color: AppColors.midGrey,
        ),
        if (_purchaseType == 'restock') ...[
          const SizedBox(height: 16),
          _sectionLabel('SELECT PRODUCT TO RESTOCK'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickProduct,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _selectedProduct != null
                      ? AppColors.gold
                      : AppColors.divider,
                  width: _selectedProduct != null ? 2 : 1.5,
                ),
              ),
              child: _selectedProduct == null
                  ? const Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: AppColors.gold,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Search or scan to find product...',
                          style: TextStyle(
                            color: AppColors.midGrey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedProduct!.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.black,
                                ),
                              ),
                              const SizedBox(height: 3),
                              StockBadgeWidget(
                                product: _selectedProduct!,
                                showLabel: true,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(
                            () => _selectedProduct = null,
                          ),
                          child: const Text(
                            'Change',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _typeCard({
    required String type,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _purchaseType == type;
    return GestureDetector(
      onTap: () => setState(() {
        _purchaseType = type;
        if (type != 'restock') {
          _selectedProduct = null;
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.08)
              : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isSelected ? color : AppColors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.midGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: color,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePurchase() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      SnackBarHelper.showError(context, 'Please select a date');
      return;
    }

    if (_purchaseType == 'restock' && _selectedProduct == null) {
      SnackBarHelper.showError(
        context,
        'Please select a product to restock.',
      );
      return;
    }

    final purchase = Purchase(
      itemName: _itemNameController.text.trim(),
      quantity: int.parse(_quantityController.text.trim()),
      costPrice: double.parse(_costPriceController.text.trim()),
      datePurchased: DateFormat('yyyy-MM-dd').format(_selectedDate!),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      purchaseType: _purchaseType,
      productId: _selectedProduct?.id,
    );

    setState(() => _isSaving = true);
    final success = await context.read<PurchaseProvider>().addPurchase(
          purchase,
        );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      HapticFeedback.lightImpact();
      if (mounted) {
        await context.read<ProductProvider>().loadProducts();
      }
      if (!mounted) return;
      SnackBarHelper.showSuccess(
        context,
        _purchaseType == 'restock'
            ? 'Restock recorded. Stock updated.'
            : 'Purchase recorded successfully',
      );
      Navigator.pop(context);
    } else {
      SnackBarHelper.showError(
        context,
        'Failed to save. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currencyLabel;
    final isRestock = _purchaseType == 'restock';

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: const VynexAppBar(
        title: 'Record Purchase',
        showBack: true,
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPurchaseTypeSection(),
            const SizedBox(height: 16),
            PurchaseFormBody(
              formKey: _formKey,
              itemNameController: _itemNameController,
              quantityController: _quantityController,
              costPriceController: _costPriceController,
              notesController: _notesController,
              selectedDate: _selectedDate,
              previewTotal: _previewTotal,
              currencyLabel: currency,
              isSaving: _isSaving,
              saveLabel: 'Save Purchase',
              onSave: _savePurchase,
              onCancel: () => Navigator.pop(context),
              onUpdatePreview: _updatePreview,
              onDateSelected: (date) {
                setState(() => _selectedDate = date);
              },
              itemNameReadOnly: isRestock,
              itemNameHelperText:
                  isRestock ? 'Auto-filled from catalog' : null,
            ),
          ],
        ),
      ),
    );
  }
}
