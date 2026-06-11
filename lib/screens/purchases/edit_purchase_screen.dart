// Edit purchase screen with pre-filled form and date backdating.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/debug_log.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/database/database_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/purchase.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/vynex_app_bar.dart';
import '../../widgets/purchases/purchase_form_body.dart';

/// Form screen for editing an existing purchase.
class EditPurchaseScreen extends StatefulWidget {
  /// Creates the edit purchase screen.
  const EditPurchaseScreen({super.key, required this.purchaseId});

  final int purchaseId;

  @override
  State<EditPurchaseScreen> createState() => _EditPurchaseScreenState();
}

class _EditPurchaseScreenState extends State<EditPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  String _previewTotal = 'KES 0.00';
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPurchase();
  }

  Future<void> _loadPurchase() async {
    try {
      final purchase = await DatabaseHelper().getPurchaseById(
        widget.purchaseId,
      );
      if (!mounted) return;

      if (purchase == null) {
        SnackBarHelper.showError(context, 'Purchase not found');
        Navigator.pop(context);
        return;
      }

      _itemNameController.text = purchase.itemName;
      _quantityController.text = purchase.quantity.toString();
      _costPriceController.text = purchase.costPrice.toString();
      _notesController.text = purchase.notes ?? '';
      _selectedDate = DateTime.parse(purchase.datePurchased);

      await context.read<SettingsProvider>().loadSettings();
      if (mounted) {
        setState(() => _isLoading = false);
        _updatePreview();
      }
    } catch (e) {
      logDebug('Edit purchase load error: $e');
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Could not load purchase. Please try again.',
        );
        Navigator.pop(context);
      }
    }
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
      id: widget.purchaseId,
      itemName: _itemNameController.text.trim(),
      quantity: int.parse(_quantityController.text.trim()),
      costPrice: double.parse(_costPriceController.text.trim()),
      datePurchased: DateFormat('yyyy-MM-dd').format(_selectedDate!),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    setState(() => _isSaving = true);
    final success = await context.read<PurchaseProvider>().updatePurchase(
          purchase,
        );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      HapticFeedback.lightImpact();
      SnackBarHelper.showSuccess(
        context,
        'Purchase updated successfully',
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
        title: 'Edit Purchase',
        showBack: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            )
          : SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
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
                saveLabel: 'Update Purchase',
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
