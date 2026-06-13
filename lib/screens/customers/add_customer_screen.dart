// Add or edit customer screen with form validation.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/validators.dart';
import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/common/vynex_app_bar.dart';
import '../../widgets/common/vynex_button.dart';
import '../../widgets/common/vynex_text_field.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key, this.editCustomerId});

  final int? editCustomerId;

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  Customer? _existingCustomer;
  bool _isLoading = true;
  bool _isSaving = false;

  bool get _isEdit => widget.editCustomerId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomerIfEditing();
    });
  }

  Future<void> _loadCustomerIfEditing() async {
    if (!_isEdit) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final customer = await context
        .read<CustomerProvider>()
        .getCustomerById(widget.editCustomerId!);

    if (!mounted) return;

    if (customer != null) {
      _existingCustomer = customer;
      _nameController.text = customer.name;
      _phoneController.text = customer.phone ?? '';
      _emailController.text = customer.email ?? '';
      _notesController.text = customer.notes ?? '';
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final today = Formatters.todayString();

    final customer = Customer(
      id: _isEdit ? widget.editCustomerId : null,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      dateAdded: _isEdit
          ? _existingCustomer!.dateAdded
          : today,
      lastUpdated: today,
    );

    final provider = context.read<CustomerProvider>();
    final success = _isEdit
        ? await provider.updateCustomer(customer)
        : await provider.addCustomer(customer);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      HapticFeedback.lightImpact();
      SnackBarHelper.showSuccess(
        context,
        _isEdit
            ? 'Customer updated successfully'
            : 'Customer added successfully',
      );
      Navigator.pop(context);
    } else {
      SnackBarHelper.showError(
        context,
        'Failed to save customer. Please try again.',
      );
    }
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.gold,
        fontWeight: FontWeight.bold,
        fontSize: 11,
        letterSpacing: 0.8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: VynexAppBar(
          title: _isEdit ? 'Edit Customer' : 'Add Customer',
          showBack: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: VynexAppBar(
        title: _isEdit ? 'Edit Customer' : 'Add Customer',
        showBack: true,
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionLabel('CUSTOMER DETAILS'),
              const SizedBox(height: 12),
              VynexTextField(
                label: 'Full Name',
                hint: 'e.g. John Kamau',
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    Validators.required(v, 'Customer name'),
                controller: _nameController,
                prefixIcon: Icons.person_rounded,
              ),
              const SizedBox(height: 12),
              VynexTextField(
                label: 'Phone Number',
                hint: 'e.g. 0712 345 678',
                keyboardType: TextInputType.phone,
                controller: _phoneController,
                validator: Validators.phoneNumber,
                prefixIcon: Icons.phone_rounded,
              ),
              const SizedBox(height: 12),
              VynexTextField(
                label: 'Email Address (Optional)',
                hint: 'e.g. john@example.com',
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                prefixIcon: Icons.email_rounded,
              ),
              const SizedBox(height: 12),
              VynexTextField(
                label: 'Notes (Optional)',
                hint: 'e.g. Regular customer, prefers delivery, '
                    'works at Equity Bank',
                maxLines: 3,
                controller: _notesController,
                prefixIcon: Icons.notes_rounded,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.gold),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.gold,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Linking customers to sales is optional. '
                        'You can add customers now and link them to '
                        'sales when recording a transaction.',
                        style: TextStyle(
                          color: AppColors.midGrey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              VynexButton.primary(
                label: _isEdit ? 'Update Customer' : 'Save Customer',
                isLoading: _isSaving,
                onPressed: _saveCustomer,
              ),
              const SizedBox(height: 12),
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
