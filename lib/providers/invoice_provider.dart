// invoice_provider.dart
// Manages invoice generation, storage and retrieval.

import 'package:flutter/foundation.dart';

import '../core/database/database_helper.dart';
import '../models/invoice.dart';
import '../models/sale.dart';

class InvoiceProvider extends ChangeNotifier {
  List<Invoice> _invoices = [];
  bool _isLoading = false;
  bool _isGenerating = false;

  List<Invoice> get invoices => _invoices;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;

  Future<void> loadInvoices() async {
    _isLoading = true;
    notifyListeners();
    try {
      final db = DatabaseHelper();
      _invoices = await db.getInvoices();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading invoices: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Generate the next sequential invoice number.
  /// Format: VYX-YYYY-XXXX where XXXX is zero-padded.
  /// Example: VYX-2026-0001
  Future<String> generateInvoiceNumber() async {
    try {
      final db = DatabaseHelper();
      final count = await db.getInvoiceCount();
      final year = DateTime.now().year;
      final seq = (count + 1).toString().padLeft(4, '0');
      return 'VYX-$year-$seq';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error generating invoice number: $e');
      }
      final fallback = DateTime.now()
          .millisecondsSinceEpoch
          .toString()
          .substring(7);
      return 'VYX-${DateTime.now().year}-$fallback';
    }
  }

  /// Create and store an invoice record for a sale.
  Future<Invoice?> createInvoice({
    required Sale sale,
    required String customerName,
    String? customerPhone,
    String? notes,
    int? customerId,
  }) async {
    _isGenerating = true;
    notifyListeners();
    try {
      final db = DatabaseHelper();
      final invoiceNumber = await generateInvoiceNumber();
      final today = DateTime.now()
          .toIso8601String()
          .substring(0, 10);

      final invoice = Invoice(
        invoiceNumber: invoiceNumber,
        saleId: sale.id,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        subtotal: sale.totalRevenue,
        total: sale.totalRevenue,
        notes: notes,
        dateIssued: today,
      );

      final id = await db.insertInvoice(invoice);
      final saved = invoice.copyWith(id: id);
      _invoices.insert(0, saved);
      notifyListeners();
      return saved;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating invoice: $e');
      }
      return null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<List<Invoice>> getInvoicesForSale(
    int saleId,
  ) async {
    try {
      final db = DatabaseHelper();
      return await db.getInvoicesForSale(saleId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading sale invoices: $e');
      }
      return [];
    }
  }

  Future<List<Invoice>> getInvoicesForCustomer(
    int customerId,
  ) async {
    try {
      final db = DatabaseHelper();
      return await db.getInvoicesForCustomer(customerId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading customer invoices: $e');
      }
      return [];
    }
  }
}
