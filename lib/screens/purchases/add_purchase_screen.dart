// Add purchase screen with form validation and date backdating.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/purchase.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/settings_provider.dart';
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

  Future<void> _savePurchase() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      SnackBarHelper.showError(context, 'Please select a date');
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
    );

    setState(() => _isSaving = true);
    final success = await context.read<PurchaseProvider>().addPurchase(
          purchase,
        );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      HapticFeedback.lightImpact();
      SnackBarHelper.showSuccess(
        context,
        'Purchase recorded successfully',
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
        child: PurchaseFormBody(
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
        ),
      ),
    );
  }
}
