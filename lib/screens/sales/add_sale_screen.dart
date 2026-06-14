// Add sale screen with form validation, preview, and date backdating.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/database/database_helper.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/validators.dart';
import '../../models/customer.dart';
import '../../models/product.dart';
import '../../models/sale.dart';
import '../../providers/product_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/catalog/product_picker_sheet.dart';
import '../../widgets/catalog/stock_badge_widget.dart';
import '../../widgets/common/vynex_app_bar.dart';
import '../../widgets/common/vynex_text_field.dart';
import '../../widgets/customers/customer_picker_sheet.dart';
import '../../widgets/sales/sale_form_body.dart';

/// Form screen for recording a new sale.
class AddSaleScreen extends StatefulWidget {
  /// Creates the add sale screen.
  const AddSaleScreen({super.key, this.preselectedCustomerId});

  final int? preselectedCustomerId;

  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _debtNoteController = TextEditingController();
  final _initialPaymentController = TextEditingController();

  DateTime? _selectedDate;
  bool _isFullyPaid = true;
  String _saleType = 'product';
  String _saleSource = 'manual';
  String _paymentMethod = 'cash';
  Product? _selectedProduct;
  Customer? _selectedCustomer;
  bool _showLossWarning = false;
  bool _isSaving = false;
  String _previewRevenue = 'KES 0.00';
  String _previewCost = 'KES 0.00';
  String _previewProfitText = 'KES 0.00';
  Color _previewProfitColor = AppColors.midGrey;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadSettings();
      _updatePreview();
      _loadPreselectedCustomer();
    });
  }

  Future<void> _loadPreselectedCustomer() async {
    final id = widget.preselectedCustomerId;
    if (id == null) return;

    final customer = await DatabaseHelper().getCustomerById(id);
    if (!mounted) return;
    if (customer != null) {
      setState(() => _selectedCustomer = customer);
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _debtNoteController.dispose();
    _initialPaymentController.dispose();
    super.dispose();
  }

  void _onFullyPaidChanged(bool value) {
    setState(() {
      _isFullyPaid = value;
      if (value) {
        _debtNoteController.clear();
        _initialPaymentController.clear();
      }
    });
  }

  void _updatePreview() {
    if (_saleType == 'service') return;

    final currency = context.read<SettingsProvider>().currencyLabel;
    final qty = int.tryParse(_quantityController.text.trim());
    final cost = double.tryParse(_costPriceController.text.trim());
    final selling = double.tryParse(_sellingPriceController.text.trim());

    if (qty != null &&
        qty > 0 &&
        cost != null &&
        cost > 0 &&
        selling != null &&
        selling > 0) {
      final revenue = qty * selling;
      final totalCost = qty * cost;
      final profit = (selling - cost) * qty;

      setState(() {
        _previewRevenue = Formatters.formatCurrency(revenue, currency);
        _previewCost = Formatters.formatCurrency(totalCost, currency);
        _showLossWarning = selling < cost;
        if (profit > 0) {
          _previewProfitText =
              '+${Formatters.formatCurrency(profit, currency)}';
          _previewProfitColor = AppColors.success;
        } else if (profit == 0) {
          _previewProfitText = Formatters.formatCurrency(0, currency);
          _previewProfitColor = AppColors.midGrey;
        } else {
          _previewProfitText =
              '-${Formatters.formatCurrency(profit.abs(), currency)}';
          _previewProfitColor = AppColors.danger;
        }
      });
    } else {
      setState(() {
        _previewRevenue = Formatters.formatCurrency(0, currency);
        _previewCost = Formatters.formatCurrency(0, currency);
        _previewProfitText = Formatters.formatCurrency(0, currency);
        _previewProfitColor = AppColors.midGrey;
        _showLossWarning = false;
      });
    }
  }

  Future<void> _pickCustomer() async {
    final customer = await CustomerPickerSheet.show(context);
    if (!mounted) return;
    if (customer != null) {
      setState(() => _selectedCustomer = customer);
    }
  }

  Widget _buildCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel('CUSTOMER (OPTIONAL)'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickCustomer,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.gold,
                width: 1.5,
              ),
            ),
            child: _selectedCustomer == null
                ? const Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        color: AppColors.gold,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Link a customer (optional)',
                        style: TextStyle(
                          color: AppColors.midGrey,
                          fontSize: 14,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.midGrey,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      _customerAvatar(_selectedCustomer!),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedCustomer!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.black,
                              ),
                            ),
                            if (_selectedCustomer!.phone != null &&
                                _selectedCustomer!.phone!.isNotEmpty)
                              Text(
                                _selectedCustomer!.phone!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.midGrey,
                                ),
                              ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _pickCustomer,
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
        const SizedBox(height: 6),
        const Text(
          'Linking a customer helps track their full '
          'purchase history in one place.',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.midGrey,
          ),
        ),
      ],
    );
  }

  Widget _customerAvatar(Customer customer) {
    final initial = customer.name.isNotEmpty
        ? customer.name[0].toUpperCase()
        : '?';
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.gold.withValues(alpha: 0.15),
        border: Border.all(color: AppColors.gold),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.gold,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Future<void> _pickProduct() async {
    final product = await ProductPickerSheet.show(context);
    if (product == null || !mounted) return;

    setState(() {
      _selectedProduct = product;
      _itemNameController.text = product.name;
      _costPriceController.text =
          product.defaultCostPrice.toStringAsFixed(2);
      _sellingPriceController.text =
          product.defaultSellingPrice.toStringAsFixed(2);
      if (_quantityController.text.isEmpty) {
        _quantityController.text = '1';
      }
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

  Widget _buildSourceSelector() {
    return Column(
      children: [
        _sourceCard(
          source: 'stock',
          icon: Icons.inventory_2_rounded,
          title: 'From My Stock',
          subtitle: 'Item is in your inventory catalog',
          color: AppColors.success,
        ),
        const SizedBox(height: 8),
        _sourceCard(
          source: 'spot_buy',
          icon: Icons.shopping_bag_rounded,
          title: 'Spot Buy',
          subtitle: 'You got it specifically for this customer',
          color: AppColors.warning,
        ),
        const SizedBox(height: 8),
        _sourceCard(
          source: 'manual',
          icon: Icons.edit_rounded,
          title: 'Manual Entry',
          subtitle: 'Enter details without catalog (classic mode)',
          color: AppColors.midGrey,
        ),
      ],
    );
  }

  Widget _sourceCard({
    required String source,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _saleSource == source;
    return GestureDetector(
      onTap: () => setState(() {
        _saleSource = source;
        _selectedProduct = null;
        if (source != 'stock') {
          _itemNameController.clear();
          _costPriceController.clear();
          _sellingPriceController.clear();
        }
        _updatePreview();
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

  Widget _buildSaleSourceSection() {
    if (_saleType != 'product') return const SizedBox.shrink();

    final currency = context.watch<SettingsProvider>().currencyLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel('WHERE IS THIS ITEM FROM?'),
        const SizedBox(height: 8),
        _buildSourceSelector(),
        if (_saleSource == 'stock') ...[
          const SizedBox(height: 16),
          _sectionLabel('SELECT PRODUCT FROM CATALOG'),
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
          if (_selectedProduct != null &&
              _selectedProduct!.isOutOfStock)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.danger),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.danger,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This product is out of stock. '
                      'You can still record the sale.',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        if (_saleSource == 'spot_buy') ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.warning,
                  size: 16,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Spot Buy: You sourced this item specifically '
                    'for this customer. No stock deduction. '
                    'Enter what you paid below.',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          VynexTextField(
            label: 'What You Paid (Spot Cost)',
            hint: 'e.g. 400.00',
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            prefixText: '$currency ',
            controller: _costPriceController,
            validator: (v) => Validators.positiveNumber(
              v,
              'Spot cost',
            ),
            onChanged: (_) => _updatePreview(),
          ),
        ],
      ],
    );
  }

  Future<void> _saveSale() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      SnackBarHelper.showError(context, 'Please select a date');
      return;
    }

    if (_saleSource == 'stock' && _selectedProduct == null) {
      SnackBarHelper.showError(
        context,
        'Please select a product from your catalog.',
      );
      return;
    }

    if (_saleSource == 'spot_buy') {
      final spotCost = double.tryParse(
        _costPriceController.text.trim(),
      );
      if (spotCost == null || spotCost <= 0) {
        SnackBarHelper.showError(
          context,
          'Please enter what you paid for this item.',
        );
        return;
      }
    }

    double initialPayment = 0.0;
    if (!_isFullyPaid) {
      final raw = _initialPaymentController.text.trim();
      if (raw.isNotEmpty) {
        initialPayment = double.tryParse(raw) ?? 0.0;
        final potentialRevenue = _saleType == 'service'
            ? (double.tryParse(_sellingPriceController.text.trim()) ??
                0.0)
            : (int.tryParse(_quantityController.text.trim()) ?? 0) *
                (double.tryParse(
                      _sellingPriceController.text.trim(),
                    ) ??
                    0.0);
        if (initialPayment >= potentialRevenue && potentialRevenue > 0) {
          SnackBarHelper.showError(
            context,
            'Initial payment equals or exceeds total. '
            'Mark the sale as fully paid instead.',
          );
          return;
        }
      }
    }

    final sale = Sale(
      itemName: _itemNameController.text.trim(),
      quantitySold: _saleType == 'service'
          ? 1
          : int.parse(_quantityController.text.trim()),
      costPrice: _saleType == 'service'
          ? 0.0
          : _saleSource == 'spot_buy'
              ? 0.0
              : double.parse(_costPriceController.text.trim()),
      sellingPrice:
          double.parse(_sellingPriceController.text.trim()),
      dateSold: DateFormat('yyyy-MM-dd').format(_selectedDate!),
      isFullyPaid: _isFullyPaid,
      debtNote: _isFullyPaid ? null : _debtNoteController.text.trim(),
      paymentMethod: _paymentMethod,
      saleType: _saleType,
      saleSource: _saleType == 'service' ? 'service' : _saleSource,
      productId: _selectedProduct?.id,
      spotCost: _saleSource == 'spot_buy'
          ? double.parse(_costPriceController.text.trim())
          : null,
      customerId: _selectedCustomer?.id,
    );

    setState(() => _isSaving = true);
    final success = await context.read<SaleProvider>().addSale(
          sale,
          initialPayment: initialPayment,
        );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      HapticFeedback.lightImpact();
      if (mounted) {
        await context.read<ProductProvider>().loadProducts();
      }
      if (!mounted) return;
      if (_saleSource == 'spot_buy') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Sale recorded. Add this item to your catalog?',
              style: TextStyle(color: AppColors.black),
            ),
            backgroundColor: AppColors.gold,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Add to Catalog',
              textColor: AppColors.black,
              onPressed: () {
                context.push(AppRoutes.addProduct);
              },
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else if (sale.isFullyPaid) {
        SnackBarHelper.showSuccess(
          context,
          'Sale recorded successfully',
        );
      } else {
        SnackBarHelper.showInfo(
          context,
          'Sale recorded. Debt entry created automatically.',
        );
      }
      Navigator.pop(context);
    } else {
      SnackBarHelper.showError(context, 'Failed to save sale.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currencyLabel;
    final isStock = _saleSource == 'stock' && _saleType == 'product';
    final isSpotBuy = _saleSource == 'spot_buy' && _saleType == 'product';

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: const VynexAppBar(
        title: 'Record Sale',
        showBack: true,
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SaleFormBody(
          formKey: _formKey,
          itemNameController: _itemNameController,
          quantityController: _quantityController,
          costPriceController: _costPriceController,
          sellingPriceController: _sellingPriceController,
          debtNoteController: _debtNoteController,
          initialPaymentController: _initialPaymentController,
          selectedDate: _selectedDate,
          currencyLabel: currency,
          isFullyPaid: _isFullyPaid,
          showLossWarning: _showLossWarning,
          previewRevenue: _previewRevenue,
          previewCost: _previewCost,
          previewProfitText: _previewProfitText,
          previewProfitColor: _previewProfitColor,
          isSaving: _isSaving,
          saveLabel: 'Save Sale',
          onSave: _saveSale,
          onCancel: () => Navigator.pop(context),
          saleType: _saleType,
          paymentMethod: _paymentMethod,
          lockSaleType: false,
          contentAfterSaleType: _buildSaleSourceSection(),
          contentBeforePayment: _buildCustomerSection(),
          itemNameReadOnly: isStock,
          costPriceReadOnly: isStock,
          hideCostPrice: isSpotBuy,
          itemNameHelperText:
              isStock ? 'Auto-filled from catalog' : null,
          costPriceHelperText:
              isStock ? 'Auto-filled from catalog' : null,
          onSaleTypeChanged: (type) {
            setState(() {
              _saleType = type;
              if (type == 'service') {
                _saleSource = 'service';
                _selectedProduct = null;
              } else if (_saleSource == 'service') {
                _saleSource = 'manual';
              }
            });
            _updatePreview();
          },
          onPaymentMethodChanged: (method) {
            setState(() => _paymentMethod = method);
          },
          onUpdatePreview: _updatePreview,
          onDateSelected: (date) => setState(() => _selectedDate = date),
          onFullyPaidChanged: _onFullyPaidChanged,
        ),
      ),
    );
  }
}
