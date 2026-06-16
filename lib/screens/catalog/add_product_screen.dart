// Add product screen with full catalog form.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({
    super.key,
    this.prefillName,
  });

  final String? prefillName;

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _thresholdController = TextEditingController(text: '5');

  int? _selectedCategoryId;
  String _selectedUnit = 'piece';
  bool _isSaving = false;
  String _profitPreview = 'KES 0.00';
  bool _profitPositive = true;

  @override
  void initState() {
    super.initState();
    if (widget.prefillName != null && widget.prefillName!.isNotEmpty) {
      _nameController.text = widget.prefillName!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
      context.read<SettingsProvider>().loadSettings();
      _updateProfitPreview();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    super.dispose();
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

  Future<void> _scanBarcode() async {
    final scanned = await PermissionHelper.scanBarcodeWithPermission(context);
    if (scanned == null || !mounted) return;

    _barcodeController.text = scanned;

    final existing = await context
        .read<ProductProvider>()
        .getProductByBarcode(scanned);

    if (!mounted) return;

    if (existing != null) {
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

  Future<void> _pickUnit() async {
    final unit = await showUnitPickerSheet(
      context,
      currentUnit: _selectedUnit,
    );
    if (!mounted || unit == null) return;
    setState(() => _selectedUnit = unit);
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final today = Formatters.todayString();
    final product = Product(
      name: _nameController.text.trim(),
      categoryId: _selectedCategoryId,
      barcode: _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim(),
      defaultCostPrice: double.parse(_costPriceController.text),
      defaultSellingPrice: double.parse(_sellingPriceController.text),
      currentStock: int.tryParse(_stockController.text) ?? 0,
      lowStockThreshold: int.tryParse(_thresholdController.text) ?? 5,
      unit: _selectedUnit,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      dateAdded: today,
      lastUpdated: today,
    );

    final success = await context.read<ProductProvider>().addProduct(
          product,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      HapticFeedback.lightImpact();
      SnackBarHelper.showSuccess(context, 'Product added to catalog');
      Navigator.pop(context);
    } else {
      SnackBarHelper.showError(
        context,
        'Failed to add product. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currencyLabel;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: const VynexAppBar(title: 'Add Product', showBack: true),
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
              const ProductFormSectionLabel(label: 'INITIAL STOCK'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        VynexTextField(
                          label: 'Current Stock',
                          hint: 'How many do you have now? e.g. 10',
                          keyboardType: TextInputType.number,
                          controller: _stockController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            final n = int.tryParse(value.trim());
                            if (n == null || n < 0) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const FieldNote(
                          text: 'Leave empty or 0 to add stock later.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        VynexTextField(
                          label: 'Alert Below',
                          hint: 'e.g. 5',
                          keyboardType: TextInputType.number,
                          controller: _thresholdController,
                        ),
                        const FieldNote(
                          text: 'Get alerted when stock drops below this.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const ProductInfoBox(
                text: 'Stock will be tracked automatically when you record '
                    'purchases (restock) and sales (from stock).',
              ),
              const SizedBox(height: 24),
              VynexButton.primary(
                label: 'Add to Catalog',
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
