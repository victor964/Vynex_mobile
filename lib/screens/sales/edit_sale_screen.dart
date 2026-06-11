// Edit sale screen with pre-filled form and date backdating.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/debug_log.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/database/database_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/sale.dart';
import '../../providers/sale_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/vynex_app_bar.dart';
import '../../widgets/sales/sale_form_body.dart';

/// Form screen for editing an existing sale.
class EditSaleScreen extends StatefulWidget {
  /// Creates the edit sale screen.
  const EditSaleScreen({super.key, required this.saleId});

  final int saleId;

  @override
  State<EditSaleScreen> createState() => _EditSaleScreenState();
}

class _EditSaleScreenState extends State<EditSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _debtNoteController = TextEditingController();

  DateTime? _selectedDate;
  bool _isFullyPaid = true;
  bool _wasFullyPaid = true;
  String _saleType = 'product';
  String _paymentMethod = 'cash';
  bool _showLossWarning = false;
  bool _isSaving = false;
  bool _isLoading = true;
  int? _saleId;
  String _previewRevenue = 'KES 0.00';
  String _previewCost = 'KES 0.00';
  String _previewProfitText = 'KES 0.00';
  Color _previewProfitColor = AppColors.midGrey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSale();
    });
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _debtNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadSale() async {
    try {
      final sale = await DatabaseHelper().getSaleById(widget.saleId);
      if (!mounted) return;

      if (sale == null) {
        SnackBarHelper.showError(context, 'Sale not found');
        Navigator.pop(context);
        return;
      }

      _saleId = sale.id;
      _itemNameController.text = sale.itemName;
      _quantityController.text = sale.quantitySold.toString();
      _costPriceController.text = sale.costPrice.toString();
      _sellingPriceController.text = sale.sellingPrice.toString();
      _debtNoteController.text = sale.debtNote ?? '';
      _selectedDate = DateTime.parse(sale.dateSold);
      _isFullyPaid = sale.isFullyPaid;
      _wasFullyPaid = sale.isFullyPaid;
      _saleType = sale.saleType;
      _paymentMethod = sale.paymentMethod;

      await context.read<SettingsProvider>().loadSettings();
      if (mounted) {
        setState(() => _isLoading = false);
        _updatePreview();
      }
    } catch (e) {
      logDebug('Edit sale load error: $e');
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Could not load sale. Please try again.',
        );
        Navigator.pop(context);
      }
    }
  }

  void _onFullyPaidChanged(bool value) {
    setState(() {
      _isFullyPaid = value;
      if (value) {
        _debtNoteController.clear();
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

  Future<void> _saveSale() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _saleId == null) return;

    final updatedSale = Sale(
      id: _saleId,
      itemName: _itemNameController.text.trim(),
      quantitySold: _saleType == 'service'
          ? 1
          : int.parse(_quantityController.text.trim()),
      costPrice: _saleType == 'service'
          ? 0.0
          : double.parse(_costPriceController.text.trim()),
      sellingPrice: double.parse(_sellingPriceController.text.trim()),
      dateSold: DateFormat('yyyy-MM-dd').format(_selectedDate!),
      isFullyPaid: _isFullyPaid,
      debtNote: _isFullyPaid ? null : _debtNoteController.text.trim(),
      paymentMethod: _paymentMethod,
      saleType: _saleType,
    );

    setState(() => _isSaving = true);
    final success = await context.read<SaleProvider>().updateSale(updatedSale);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      HapticFeedback.lightImpact();
      if (_wasFullyPaid == _isFullyPaid) {
        SnackBarHelper.showSuccess(
          context,
          'Sale updated successfully',
        );
      } else if (!_isFullyPaid) {
        SnackBarHelper.showInfo(
          context,
          'Sale updated. Debt entry created.',
        );
      } else {
        SnackBarHelper.showSuccess(
          context,
          'Sale updated. Debt cleared.',
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

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: VynexAppBar(
          title: 'Edit Sale',
          showBack: true,
        ),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: const VynexAppBar(
        title: 'Edit Sale',
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
          selectedDate: _selectedDate,
          currencyLabel: currency,
          isFullyPaid: _isFullyPaid,
          showLossWarning: _showLossWarning,
          previewRevenue: _previewRevenue,
          previewCost: _previewCost,
          previewProfitText: _previewProfitText,
          previewProfitColor: _previewProfitColor,
          isSaving: _isSaving,
          saveLabel: 'Save Changes',
          onSave: _saveSale,
          onCancel: () => Navigator.pop(context),
          saleType: _saleType,
          paymentMethod: _paymentMethod,
          lockSaleType: true,
          onSaleTypeChanged: (_) {},
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
