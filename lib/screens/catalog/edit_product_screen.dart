// Edit product screen with pre-filled catalog form.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/database/database_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/permission_helper.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/validators.dart';
import '../../models/product.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/catalog/category_sheets.dart';
import '../../widgets/catalog/product_form_widgets.dart';
import '../../widgets/common/vynex_app_bar.dart';
import '../../widgets/common/vynex_button.dart';
import '../../widgets/common/vynex_text_field.dart';

class EditProductScreen extends StatefulWidget {
  const EditProductScreen({super.key, required this.productId});

  final int productId;

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _thresholdController = TextEditingController();

  Product? _product;
  int? _selectedCategoryId;
  String _selectedUnit = 'piece';
  bool _isLoading = true;
  bool _isSaving = false;
  String _profitPreview = 'KES 0.00';
  bool _profitPositive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProduct();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    try {
      if (!mounted) return;
      await context.read<CategoryProvider>().loadCategories();
      if (!mounted) return;
      await context.read<SettingsProvider>().loadSettings();
      final product = await DatabaseHelper().getProductById(
        widget.productId,
      );
      if (!mounted) return;

      if (product == null) {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(context, 'Product not found');
        Navigator.pop(context);
        return;
      }

      _product = product;
      _nameController.text = product.name;
      _barcodeController.text = product.barcode ?? '';
      _descriptionController.text = product.description ?? '';
      _costPriceController.text = product.defaultCostPrice.toString();
      _sellingPriceController.text =
          product.defaultSellingPrice.toString();
      _thresholdController.text =
          product.lowStockThreshold.toString();
      _selectedCategoryId = product.categoryId;
      _selectedUnit = product.unit;

      setState(() => _isLoading = false);
      _updateProfitPreview();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(context, 'Failed to load product');
      }
    }
  }

  void _updateProfitPreview() {
    setState(() {
      _profitPreview = buildProfitPreviewText(
        context,
        _costPriceController,
        _sellingPriceController,
      );
      _profitPositive = isProfitPositive(
        _costPriceController,
        _sellingPriceController,
      );
    });
  }

  String? _selectedCategoryName() {
    if (_selectedCategoryId == null) return null;
    return context
        .read<CategoryProvider>()
        .getCategoryById(_selectedCategoryId)
        ?.name;
  }

  Future<void> _scanBarcode() async {
    final scanned = await PermissionHelper.scanBarcodeWithPermission(context);
    if (scanned == null || !mounted) return;

    _barcodeController.text = scanned;

    final existing = await context
        .read<ProductProvider>()
        .getProductByBarcode(scanned);

    if (!mounted) return;

    if (existing != null && existing.id != widget.productId) {
      SnackBarHelper.showInfo(
        context,
        'Barcode already linked to "${existing.name}".',
      );
    } else {
      HapticFeedback.lightImpact();
      SnackBarHelper.showSuccess(
        context,
        'Barcode scanned successfully.',
      );
    }
  }

  Future<void> _pickCategory() async {
    final id = await showCategoryPickerSheet(
      context,
      selectedCategoryId: _selectedCategoryId,
    );
    if (!mounted) return;
    if (id == kCategoryPickerAddNew) {
      await showAddCategoryBottomSheet(context);
      return;
    }
    if (id == _selectedCategoryId) return;
    setState(() => _selectedCategoryId = id);
  }

  Future<void> _pickUnit() async {
    final unit = await showUnitPickerSheet(
      context,
      currentUnit: _selectedUnit,
    );
    if (!mounted || unit == null) return;
    setState(() => _selectedUnit = unit);
  }

  Future<void> _saveProduct() async {
    if (_product == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final today = Formatters.todayString();
    final updated = _product!.copyWith(
      name: _nameController.text.trim(),
      categoryId: _selectedCategoryId,
      barcode: _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim(),
      defaultCostPrice: double.parse(_costPriceController.text),
      defaultSellingPrice: double.parse(_sellingPriceController.text),
      lowStockThreshold: int.tryParse(_thresholdController.text) ?? 5,
      unit: _selectedUnit,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      lastUpdated: today,
    );

    final success = await context.read<ProductProvider>().updateProduct(
          updated,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      HapticFeedback.lightImpact();
      SnackBarHelper.showSuccess(context, 'Product updated');
      Navigator.pop(context);
    } else {
      SnackBarHelper.showError(context, 'Failed to update product');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currencyLabel;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: VynexAppBar(title: 'Edit Product', showBack: true),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    final product = _product!;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: const VynexAppBar(title: 'Edit Product', showBack: true),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ProductFormSectionLabel(label: 'PRODUCT DETAILS'),
              VynexTextField(
                label: 'Product Name',
                hint: 'e.g. Flower Cable 1m, 25W Bulb, iPhone Case',
                textCapitalization: TextCapitalization.words,
                validator: (v) => Validators.required(v, 'Product name'),
                controller: _nameController,
              ),
              const SizedBox(height: 12),
              CategoryPickerField(
                selectedName: _selectedCategoryName(),
                onTap: _pickCategory,
              ),
              const SizedBox(height: 12),
              BarcodeField(
                controller: _barcodeController,
                onScan: _scanBarcode,
              ),
              const SizedBox(height: 12),
              UnitPickerField(
                selectedUnit: _selectedUnit,
                onTap: _pickUnit,
              ),
              const SizedBox(height: 12),
              VynexTextField(
                label: 'Description (Optional)',
                hint: 'Any details about this product',
                maxLines: 2,
                controller: _descriptionController,
              ),
              const SizedBox(height: 20),
              const ProductFormSectionLabel(label: 'DEFAULT PRICING'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: VynexTextField(
                      label: 'Cost Price',
                      hint: 'e.g. 85.00',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefixText: '$currency ',
                      controller: _costPriceController,
                      validator: (v) =>
                          Validators.positiveNumber(v, 'Cost price'),
                      onChanged: (_) => _updateProfitPreview(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: VynexTextField(
                      label: 'Selling Price',
                      hint: 'e.g. 120.00',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefixText: '$currency ',
                      controller: _sellingPriceController,
                      validator: (v) =>
                          Validators.positiveNumber(v, 'Selling price'),
                      onChanged: (_) => _updateProfitPreview(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ProductProfitPreview(
                profitText: _profitPreview,
                isPositive: _profitPositive,
              ),
              const SizedBox(height: 20),
              const ProductFormSectionLabel(label: 'STOCK INFO'),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Current stock: ${product.currentStock} '
                        '${product.unit}s',
                        style: const TextStyle(
                          color: AppColors.darkGrey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push(
                        '/inventory/adjust/${product.id}',
                      ),
                      child: const Text(
                        'Adjust Stock',
                        style: TextStyle(color: AppColors.gold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              VynexTextField(
                label: 'Alert Below',
                hint: 'e.g. 5',
                keyboardType: TextInputType.number,
                controller: _thresholdController,
              ),
              const FieldNote(
                text: 'Get alerted when stock drops below this.',
              ),
              const SizedBox(height: 24),
              VynexButton.primary(
                label: 'Save Changes',
                isLoading: _isSaving,
                onPressed: _saveProduct,
              ),
              const SizedBox(height: 10),
              VynexButton.secondary(
                label: 'Cancel',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
