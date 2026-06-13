// Stock adjustment screen for manual inventory corrections.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/database/database_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/validators.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../providers/category_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/catalog/stock_badge_widget.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/vynex_app_bar.dart';
import '../../widgets/common/vynex_button.dart';
import '../../widgets/common/vynex_card.dart';
import '../../widgets/common/vynex_text_field.dart';

class StockAdjustmentScreen extends StatefulWidget {
  const StockAdjustmentScreen({
    super.key,
    required this.productId,
    this.mode = 'adjust',
  });

  final int productId;
  final String mode;

  @override
  State<StockAdjustmentScreen> createState() =>
      _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends State<StockAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();

  Product? _product;
  Category? _category;
  bool _isLoading = true;
  late String _formMode;

  @override
  void initState() {
    super.initState();
    _formMode = _resolveInitialFormMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProduct();
    });
    _quantityController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  String _resolveInitialFormMode() {
    switch (widget.mode) {
      case 'add':
      case 'remove':
      case 'set':
        return widget.mode;
      default:
        return 'add';
    }
  }

  bool get _showModeSelector => widget.mode == 'adjust';

  String get _appBarTitle {
    switch (_formMode) {
      case 'add':
        return 'Add Stock';
      case 'remove':
        return 'Remove Stock';
      case 'set':
        return 'Set Stock Count';
      default:
        return 'Adjust Stock';
    }
  }

  Future<void> _loadProduct() async {
    try {
      final db = DatabaseHelper();
      final product = await db.getProductById(widget.productId);
      if (!mounted) return;

      if (product == null) {
        setState(() => _isLoading = false);
        return;
      }

      final categoryProvider = context.read<CategoryProvider>();
      if (categoryProvider.categories.isEmpty) {
        await categoryProvider.loadCategories();
      }
      if (!mounted) return;

      setState(() {
        _product = product;
        _category = categoryProvider.getCategoryById(
          product.categoryId,
        );
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> get _reasonPresets {
    switch (_formMode) {
      case 'add':
        return [
          'New stock',
          'Customer return',
          'Found item',
          'Transfer in',
        ];
      case 'remove':
        return [
          'Damaged',
          'Lost',
          'Expired',
          'Transfer out',
          'Used in shop',
        ];
      case 'set':
        return [
          'Monthly count',
          'Annual audit',
          'System correction',
        ];
      default:
        return [];
    }
  }

  String get _quantityHint {
    switch (_formMode) {
      case 'add':
        return 'e.g. 10';
      case 'remove':
        return 'e.g. 3';
      case 'set':
        return 'e.g. 25';
      default:
        return 'e.g. 5';
    }
  }

  String get _quantityLabel {
    switch (_formMode) {
      case 'add':
        return 'Quantity to Add';
      case 'remove':
        return 'Quantity to Remove';
      case 'set':
        return 'Set Stock to Exact Quantity';
      default:
        return 'Quantity';
    }
  }

  String get _reasonHint {
    switch (_formMode) {
      case 'add':
        return 'e.g. New stock received, Returned by customer';
      case 'remove':
        return 'e.g. Damaged goods, Used for display';
      case 'set':
        return 'e.g. Monthly stock count, Recount after audit';
      default:
        return 'Enter a reason for this adjustment';
    }
  }

  String get _saveButtonLabel {
    switch (_formMode) {
      case 'add':
        return 'Add to Stock';
      case 'remove':
        return 'Remove from Stock';
      case 'set':
        return 'Update Stock Count';
      default:
        return 'Save Adjustment';
    }
  }

  int? get _parsedQuantity {
    return int.tryParse(_quantityController.text.trim());
  }

  Widget? _buildPreviewRow(Product product) {
    final qty = _parsedQuantity;
    if (qty == null) return null;

    switch (_formMode) {
      case 'add':
        return Text(
          'New stock will be: ${product.currentStock + qty} '
          '${product.unit}s',
          style: const TextStyle(
            color: AppColors.success,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        );
      case 'remove':
        final newStock = product.currentStock - qty;
        final color = newStock <= 0
            ? AppColors.danger
            : AppColors.warning;
        return Text(
          'New stock will be: '
          '${newStock < 0 ? 0 : newStock} ${product.unit}s',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        );
      case 'set':
        final diff = (qty - product.currentStock).abs();
        if (qty == product.currentStock) {
          return const Text(
            'No change',
            style: TextStyle(
              color: AppColors.midGrey,
              fontSize: 12,
            ),
          );
        }
        if (qty > product.currentStock) {
          return Text(
            'Increasing by $diff units',
            style: const TextStyle(
              color: AppColors.success,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          );
        }
        return Text(
          'Decreasing by $diff units',
          style: const TextStyle(
            color: AppColors.warning,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        );
      default:
        return null;
    }
  }

  String? _quantityValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Quantity is required';
    }
    final qty = int.tryParse(value.trim());
    if (qty == null) {
      return 'Enter a whole number';
    }
    if (_formMode == 'set') {
      if (qty < 0) return 'Quantity cannot be negative';
      return null;
    }
    if (qty <= 0) {
      return 'Quantity must be at least 1';
    }
    return null;
  }

  void _applyReasonPreset(String preset) {
    final current = _reasonController.text.trim();
    if (current.isEmpty) {
      _reasonController.text = preset;
    } else if (!current.contains(preset)) {
      _reasonController.text = '$current, $preset';
    }
    setState(() {});
  }

  Future<void> _saveAdjustment() async {
    if (!_formKey.currentState!.validate()) return;

    final product = _product;
    if (product == null) return;

    final qty = _parsedQuantity!;
    final reason = _reasonController.text.trim();
    final provider = context.read<InventoryProvider>();

    if (_formMode == 'remove') {
      final newStock = product.currentStock - qty;
      if (newStock < 0) {
        final confirmed = await showConfirmDialog(
          context,
          title: 'Confirm Stock Removal',
          message: 'Stock will go to 0 (cannot go negative). '
              'Are you sure you want to remove this stock?',
          confirmLabel: 'Yes, Remove',
        );
        if (!confirmed || !mounted) return;
      }
    }

    bool success;
    if (_formMode == 'set') {
      success = await provider.setStock(
        productId: widget.productId,
        exactQuantity: qty,
        reason: reason,
      );
    } else {
      final adjustmentQty = _formMode == 'remove' ? -qty : qty;
      if (_formMode == 'add') {
        final newStock = product.currentStock + qty;
        if (newStock < 0) {
          final confirmed = await showConfirmDialog(
            context,
            title: 'Confirm Adjustment',
            message: 'Stock will go to 0 (cannot go negative). '
                'Are you sure you want to continue?',
            confirmLabel: 'Yes, Continue',
          );
          if (!confirmed || !mounted) return;
        }
      }
      success = await provider.adjustStock(
        productId: widget.productId,
        adjustmentQuantity: adjustmentQty,
        reason: reason,
      );
    }

    if (!mounted) return;

    if (success) {
      HapticFeedback.lightImpact();
      SnackBarHelper.showSuccess(
        context,
        'Stock updated successfully',
      );
      context.pop();
    } else {
      SnackBarHelper.showError(
        context,
        'Failed to update stock. Please try again.',
      );
    }
  }

  Color _stockColor(Product product) {
    if (product.isOutOfStock) return AppColors.danger;
    if (product.isLowStock) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: VynexAppBar(
          title: _appBarTitle,
          showBack: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    final product = _product;
    if (product == null) {
      return Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: VynexAppBar(
          title: _appBarTitle,
          showBack: true,
        ),
        body: const Center(child: Text('Product not found')),
      );
    }

    final stockColor = _stockColor(product);
    final preview = _buildPreviewRow(product);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: VynexAppBar(
        title: _appBarTitle,
        showBack: true,
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VynexCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                _category?.name ?? 'Uncategorized',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.midGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StockBadgeWidget(product: product),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Current Stock:',
                          style: TextStyle(
                            color: AppColors.midGrey,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${product.currentStock} ${product.unit}s',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: stockColor,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Low stock alert:',
                          style: TextStyle(
                            color: AppColors.midGrey,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Below ${product.lowStockThreshold} '
                          '${product.unit}s',
                          style: const TextStyle(
                            color: AppColors.midGrey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_showModeSelector) ...[
                const SizedBox(height: 16),
                _buildModeSelector(),
              ],
              const SizedBox(height: 16),
              Text(
                _quantityLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              VynexTextField(
                controller: _quantityController,
                hint: _quantityHint,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: _quantityValidator,
              ),
              if (preview != null) ...[
                const SizedBox(height: 8),
                preview,
              ],
              const SizedBox(height: 16),
              VynexTextField(
                label: 'Reason for Adjustment',
                controller: _reasonController,
                hint: _reasonHint,
                maxLines: 2,
                validator: (v) => Validators.required(v, 'Reason'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _reasonPresets.map((preset) {
                  return ActionChip(
                    label: Text(
                      preset,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.gold,
                      ),
                    ),
                    backgroundColor: AppColors.white,
                    side: const BorderSide(color: AppColors.gold),
                    onPressed: () => _applyReasonPreset(preset),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Consumer<InventoryProvider>(
            builder: (context, provider, _) {
              return VynexButton.primary(
                label: _saveButtonLabel,
                isLoading: provider.isAdjusting,
                onPressed: _saveAdjustment,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(
          child: _modePill(
            label: '+ Add Stock',
            mode: 'add',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _modePill(
            label: '- Remove Stock',
            mode: 'remove',
            color: AppColors.danger,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _modePill(
            label: '= Set Exact Count',
            mode: 'set',
            color: AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _modePill({
    required String label,
    required String mode,
    required Color color,
  }) {
    final selected = _formMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _formMode = mode;
          _quantityController.clear();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color : AppColors.lightGrey,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected ? color : AppColors.midGrey,
          ),
        ),
      ),
    );
  }
}
