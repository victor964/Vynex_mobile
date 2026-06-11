// Add sale screen with form validation, preview, and date backdating.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/sale.dart';
import '../../providers/sale_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/vynex_app_bar.dart';
import '../../widgets/sales/sale_form_body.dart';

/// Form screen for recording a new sale.
class AddSaleScreen extends StatefulWidget {
  /// Creates the add sale screen.
  const AddSaleScreen({super.key});

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
  String _paymentMethod = 'cash';
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
    });
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

  Future<void> _saveSale() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      SnackBarHelper.showError(context, 'Please select a date');
      return;
    }

    double initialPayment = 0.0;
    if (!_isFullyPaid) {
      final raw = _initialPaymentController.text.trim();
      if (raw.isNotEmpty) {
        initialPayment = double.tryParse(raw) ?? 0.0;
        final potentialRevenue = _saleType == 'service'
            ? (double.tryParse(_sellingPriceController.text.trim()) ?? 0.0)
            : (int.tryParse(_quantityController.text.trim()) ?? 0) *
                (double.tryParse(_sellingPriceController.text.trim()) ?? 0.0);
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
          : double.parse(_costPriceController.text.trim()),
      sellingPrice: double.parse(_sellingPriceController.text.trim()),
      dateSold: DateFormat('yyyy-MM-dd').format(_selectedDate!),
      isFullyPaid: _isFullyPaid,
      debtNote: _isFullyPaid ? null : _debtNoteController.text.trim(),
      paymentMethod: _paymentMethod,
      saleType: _saleType,
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
      if (sale.isFullyPaid) {
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
          onSaleTypeChanged: (type) {
            setState(() => _saleType = type);
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
