// barcode_service.dart
// Utility for barcode validation and formatting.
// Camera scanning is handled by BarcodeScannerSheet.

class BarcodeService {
  BarcodeService._();

  /// Validate that a barcode string is usable.
  /// Returns true if the barcode is non-empty and
  /// contains only valid characters.
  static bool isValidBarcode(String? barcode) {
    if (barcode == null || barcode.trim().isEmpty) {
      return false;
    }
    return RegExp(r'^[a-zA-Z0-9\-\s]+$').hasMatch(barcode.trim());
  }

  /// Clean and normalize a scanned barcode value.
  /// Trims whitespace and removes non-printable chars.
  static String cleanBarcode(String raw) {
    return raw.trim().replaceAll(
      RegExp(r'[^\x20-\x7E]'),
      '',
    );
  }

  /// Get a human-readable barcode format name.
  /// barcodeType comes from BarcodeFormat in mobile_scanner.
  static String formatName(String barcodeType) {
    switch (barcodeType.toLowerCase()) {
      case 'ean13':
        return 'EAN-13';
      case 'ean8':
        return 'EAN-8';
      case 'upca':
        return 'UPC-A';
      case 'upce':
        return 'UPC-E';
      case 'qrcode':
        return 'QR Code';
      case 'code128':
        return 'Code 128';
      case 'code39':
        return 'Code 39';
      case 'datamatrix':
        return 'Data Matrix';
      default:
        return barcodeType.toUpperCase();
    }
  }
}
