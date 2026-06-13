// Invoice preview screen with setup form, PDF preview and share.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/database/database_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/invoice_pdf_service.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/validators.dart';
import '../../models/business_settings.dart';
import '../../models/customer.dart';
import '../../models/invoice.dart';
import '../../models/sale.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/vynex_app_bar.dart';
import '../../widgets/common/vynex_button.dart';
import '../../widgets/common/vynex_card.dart';
import '../../widgets/common/vynex_text_field.dart';

class InvoicePreviewScreen extends StatefulWidget {
  const InvoicePreviewScreen({
    super.key,
    required this.saleId,
    this.existingInvoiceId,
  });

  final int saleId;
  final int? existingInvoiceId;

  @override
  State<InvoicePreviewScreen> createState() =>
      _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  Sale? _sale;
  Invoice? _invoice;
  List<Invoice> _existingInvoices = [];
  String? _pdfPath;
  bool _isLoading = true;
  bool _isSharing = false;
  bool _showSetupForm = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await context.read<SettingsProvider>().loadSettings();
      final db = DatabaseHelper();
      final sale = await db.getSaleById(widget.saleId);
      final existingInvoices =
          await db.getInvoicesForSale(widget.saleId);

      Customer? customer;
      if (sale?.customerId != null) {
        customer = await db.getCustomerById(sale!.customerId!);
      }

      Invoice? invoice;
      if (widget.existingInvoiceId != null) {
        invoice = await db.getInvoiceById(
          widget.existingInvoiceId!,
        );
      } else if (existingInvoices.isNotEmpty) {
        invoice = existingInvoices.first;
      }

      if (customer != null) {
        _customerNameController.text = customer.name;
        if (customer.phone != null && customer.phone!.isNotEmpty) {
          _customerPhoneController.text = customer.phone!;
        }
      }

      String? pdfPath;
      if (!mounted) return;
      final settings =
          context.read<SettingsProvider>().settings;
      if (invoice != null && sale != null && settings != null) {
        pdfPath = await InvoicePdfService.generateInvoicePdf(
          invoice: invoice,
          sale: sale,
          settings: settings,
        );
      }

      if (mounted) {
        setState(() {
          _sale = sale;
          _existingInvoices = existingInvoices;
          _invoice = invoice;
          _pdfPath = pdfPath;
          _showSetupForm = existingInvoices.isEmpty;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(
          context,
          'Could not load invoice data.',
        );
      }
    }
  }

  Future<void> _generateInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    final sale = _sale;
    final settings = context.read<SettingsProvider>().settings;
    if (sale == null || settings == null) return;

    final invoice = await context.read<InvoiceProvider>().createInvoice(
          sale: sale,
          customerName: _customerNameController.text.trim(),
          customerPhone: _customerPhoneController.text.trim().isEmpty
              ? null
              : _customerPhoneController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          customerId: sale.customerId,
        );

    if (!mounted) return;

    if (invoice == null) {
      SnackBarHelper.showError(
        context,
        'Failed to generate invoice. Please try again.',
      );
      return;
    }

    final pdfPath = await InvoicePdfService.generateInvoicePdf(
      invoice: invoice,
      sale: sale,
      settings: settings,
    );

    if (!mounted) return;

    setState(() {
      _invoice = invoice;
      _pdfPath = pdfPath;
      _showSetupForm = false;
      _existingInvoices = [invoice, ..._existingInvoices];
    });

    HapticFeedback.lightImpact();
    SnackBarHelper.showSuccess(
      context,
      'Invoice ${invoice.invoiceNumber} generated',
    );
  }

  Future<void> _shareInvoice([Invoice? invoice]) async {
    final inv = invoice ?? _invoice;
    final sale = _sale;
    final settings = context.read<SettingsProvider>().settings;
    if (inv == null || sale == null || settings == null) return;

    setState(() => _isSharing = true);
    try {
      final path = _pdfPath ??
          await InvoicePdfService.generateInvoicePdf(
            invoice: inv,
            sale: sale,
            settings: settings,
          );
      if (path == null) {
        if (mounted) {
          SnackBarHelper.showError(
            context,
            'Could not generate PDF.',
          );
        }
        return;
      }
      await InvoicePdfService.sharePdf(path);
      if (mounted && invoice == null) {
        setState(() => _pdfPath = path);
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _resetToSetupForm() {
    setState(() {
      _showSetupForm = true;
      _invoice = null;
      _pdfPath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isGenerating =
        context.watch<InvoiceProvider>().isGenerating;
    final settings = context.watch<SettingsProvider>().settings;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: VynexAppBar(
          title: 'Invoice Preview',
          showBack: true,
        ),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    final sale = _sale;
    if (sale == null || settings == null) {
      return const Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: VynexAppBar(
          title: 'Invoice Preview',
          showBack: true,
        ),
        body: Center(child: Text('Sale not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: VynexAppBar(
        title: 'Invoice Preview',
        showBack: true,
        actions: [
          if (_invoice != null)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              color: AppColors.gold,
              onPressed: _isSharing ? null : () => _shareInvoice(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_showSetupForm && _invoice == null)
              _buildSetupSection(),
            if (_invoice != null) ...[
              _InvoicePreviewCard(
                invoice: _invoice!,
                sale: sale,
                settings: settings,
              ),
              const SizedBox(height: 16),
              _buildPreviousInvoicesSection(),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _buildBottomActions(isGenerating),
        ),
      ),
    );
  }

  Widget _buildBottomActions(bool isGenerating) {
    if (_showSetupForm && _invoice == null) {
      return VynexButton.primary(
        label: 'Generate Invoice',
        isLoading: isGenerating,
        onPressed: isGenerating ? null : _generateInvoice,
      );
    }

    if (_invoice != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VynexButton.primary(
            label: 'Share Invoice PDF',
            icon: Icons.share_rounded,
            isLoading: _isSharing,
            onPressed: _isSharing ? null : () => _shareInvoice(),
          ),
          if (_existingInvoices.isNotEmpty && !_showSetupForm) ...[
            const SizedBox(height: 8),
            VynexButton.secondary(
              label: 'Generate New Invoice',
              onPressed: _resetToSetupForm,
            ),
          ],
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSetupSection() {
    return VynexCard(
      hasAccent: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.gold,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Invoice Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            VynexTextField(
              label: 'Customer Name',
              hint: 'e.g. John Kamau',
              controller: _customerNameController,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  Validators.required(v, 'Customer name'),
            ),
            const SizedBox(height: 12),
            VynexTextField(
              label: 'Customer Phone',
              hint: 'e.g. 0712 345 678',
              controller: _customerPhoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            VynexTextField(
              label: 'Notes (Optional)',
              hint: 'e.g. Thank you for shopping with us',
              controller: _notesController,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviousInvoicesSection() {
    if (_existingInvoices.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Previously generated invoices:',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.midGrey,
          ),
        ),
        const SizedBox(height: 8),
        ..._existingInvoices.map(_buildPreviousInvoiceRow),
      ],
    );
  }

  Widget _buildPreviousInvoiceRow(Invoice inv) {
    final isCurrent = _invoice?.id == inv.id;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inv.invoiceNumber,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isCurrent
                        ? AppColors.gold
                        : AppColors.black,
                  ),
                ),
                Text(
                  Formatters.formatDate(inv.dateIssued),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.midGrey,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: _isSharing
                ? null
                : () => _shareInvoice(inv),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: AppColors.gold,
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Share',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoicePreviewCard extends StatelessWidget {
  const _InvoicePreviewCard({
    required this.invoice,
    required this.sale,
    required this.settings,
  });

  final Invoice invoice;
  final Sale sale;
  final BusinessSettings settings;

  @override
  Widget build(BuildContext context) {
    final currency = settings.currencyLabel;
    final total = sale.potentialRevenue;
    final collected = sale.totalRevenue;
    final isPaid = sale.isFullyPaid;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.black,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.gold,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'V',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            settings.businessName.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1,
                            ),
                          ),
                          if (settings
                              .businessTagline.isNotEmpty)
                            Text(
                              settings.businessTagline,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.midGrey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          if (settings.phoneNumber.isNotEmpty)
                            Text(
                              'Tel: ${settings.phoneNumber}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.midGrey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.black,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'INVOICE',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    invoice.invoiceNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    Formatters.formatDate(invoice.dateIssued),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.midGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 3, color: AppColors.gold),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _PreviewInfoBox(
                  title: 'INVOICE DETAILS',
                  rows: [
                    _PreviewRow(
                      'Invoice No.',
                      invoice.invoiceNumber,
                    ),
                    _PreviewRow(
                      'Date Issued',
                      Formatters.formatDate(
                        invoice.dateIssued,
                      ),
                    ),
                    const _PreviewRow('Status', 'ISSUED'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PreviewInfoBox(
                  title: 'BILLED TO',
                  rows: [
                    _PreviewRow(
                      invoice.customerName,
                      '',
                      isBold: true,
                    ),
                    if (invoice.customerPhone != null &&
                        invoice.customerPhone!.isNotEmpty)
                      _PreviewRow(
                        invoice.customerPhone!,
                        '',
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildItemsTable(currency),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 220,
              child: Column(
                children: [
                  _PreviewTotalRow(
                    'Subtotal',
                    Formatters.formatCurrency(total, currency),
                  ),
                  const Divider(color: AppColors.lightGrey),
                  _PreviewTotalRow(
                    'TOTAL',
                    Formatters.formatCurrency(total, currency),
                    isHeader: true,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? AppColors.success
                          : AppColors.danger,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isPaid
                          ? 'PAID IN FULL'
                          : 'PAYMENT PENDING',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (!isPaid) ...[
                    const SizedBox(height: 6),
                    _PreviewTotalRow(
                      'Collected so far',
                      Formatters.formatCurrency(
                        collected,
                        currency,
                      ),
                      valueColor: AppColors.success,
                    ),
                    _PreviewTotalRow(
                      'Balance remaining',
                      Formatters.formatCurrency(
                        total - collected,
                        currency,
                      ),
                      valueColor: AppColors.danger,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 10),
                  children: [
                    const TextSpan(
                      text: 'Payment Method: ',
                      style: TextStyle(color: AppColors.midGrey),
                    ),
                    TextSpan(
                      text: sale.paymentMethodLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (invoice.notes != null &&
              invoice.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gold),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NOTES',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    invoice.notes!,
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Divider(color: AppColors.gold, thickness: 2),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thank you for your business!',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.midGrey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              Text(
                settings.businessName,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'Generated by Vynex Business Manager',
              style: TextStyle(
                fontSize: 8,
                color: AppColors.lightGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable(String currency) {
    return Table(
      border: const TableBorder(
        bottom: BorderSide(color: AppColors.gold, width: 2),
        horizontalInside: BorderSide(
          color: AppColors.lightGrey,
          width: 1,
        ),
      ),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FixedColumnWidth(40),
        2: FixedColumnWidth(72),
        3: FixedColumnWidth(72),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(
            color: AppColors.black,
          ),
          children: [
            _tableHeader('ITEM'),
            _tableHeader('QTY', center: true),
            _tableHeader('UNIT', right: true),
            _tableHeader('AMT', right: true),
          ],
        ),
        TableRow(
          decoration: BoxDecoration(
            color: AppColors.lightGrey.withValues(alpha: 0.5),
          ),
          children: [
            _tableCell(sale.itemName),
            _tableCell(
              sale.isService ? '1' : '${sale.quantitySold}',
              center: true,
            ),
            _tableCell(
              Formatters.formatCurrency(
                sale.sellingPrice,
                currency,
              ),
              right: true,
            ),
            _tableCell(
              Formatters.formatCurrency(
                sale.potentialRevenue,
                currency,
              ),
              right: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _tableHeader(
    String text, {
    bool center = false,
    bool right = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 8,
      ),
      child: Text(
        text,
        textAlign: center
            ? TextAlign.center
            : right
                ? TextAlign.right
                : TextAlign.left,
        style: const TextStyle(
          color: AppColors.gold,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _tableCell(
    String text, {
    bool center = false,
    bool right = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 8,
      ),
      child: Text(
        text,
        textAlign: center
            ? TextAlign.center
            : right
                ? TextAlign.right
                : TextAlign.left,
        style: const TextStyle(fontSize: 10),
      ),
    );
  }
}

class _PreviewInfoBox extends StatelessWidget {
  const _PreviewInfoBox({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<_PreviewRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.midGrey,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...rows.map((r) => r.build()),
        ],
      ),
    );
  }
}

class _PreviewRow {
  const _PreviewRow(
    this.label,
    this.value, {
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  Widget build() {
    if (value.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 13 : 10,
            fontWeight:
                isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? AppColors.black : AppColors.midGrey,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.midGrey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewTotalRow extends StatelessWidget {
  const _PreviewTotalRow(
    this.label,
    this.value, {
    this.isHeader = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool isHeader;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isHeader ? 12 : 10,
              fontWeight:
                  isHeader ? FontWeight.bold : FontWeight.normal,
              color: isHeader ? AppColors.black : AppColors.midGrey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isHeader ? 14 : 10,
              fontWeight:
                  isHeader ? FontWeight.bold : FontWeight.normal,
              color: valueColor ??
                  (isHeader ? AppColors.black : AppColors.midGrey),
            ),
          ),
        ],
      ),
    );
  }
}
