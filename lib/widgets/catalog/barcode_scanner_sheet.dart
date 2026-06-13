// barcode_scanner_sheet.dart
// Modal bottom sheet with camera barcode scanner.
// Returns the scanned barcode string via Navigator.pop()
// or null if the user cancels without scanning.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/barcode_service.dart';

class BarcodeScannerSheet extends StatefulWidget {
  const BarcodeScannerSheet({super.key});

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet>
    with SingleTickerProviderStateMixin {
  bool _torchOn = false;
  bool _isProcessing = false;
  late MobileScannerController _controller;
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanLineController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    if (mounted) {
      setState(() => _torchOn = !_torchOn);
    }
  }

  Future<void> _flipCamera() async {
    await _controller.switchCamera();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final value = barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;
    final cleaned = BarcodeService.cleanBarcode(value);
    if (!BarcodeService.isValidBarcode(cleaned)) return;

    _isProcessing = true;
    HapticFeedback.mediumImpact();
    Navigator.pop(context, cleaned);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.midGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Scan Barcode',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.white),
                    onPressed: () => Navigator.pop(context, null),
                  ),
                ],
              ),
            ),
            const Text(
              'Point camera at the barcode',
              style: TextStyle(
                color: AppColors.midGrey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: _controller,
                          onDetect: _onDetect,
                        ),
                        _ScanOverlay(scanLineAnimation: _scanLineAnimation),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _torchOn ? Icons.flash_on : Icons.flash_off,
                    color: _torchOn ? AppColors.gold : AppColors.midGrey,
                    size: 28,
                  ),
                  onPressed: _toggleTorch,
                ),
                const SizedBox(width: 32),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 32),
                IconButton(
                  icon: const Icon(
                    Icons.flip_camera_ios_rounded,
                    color: AppColors.midGrey,
                    size: 28,
                  ),
                  onPressed: _flipCamera,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text(
                'Type barcode manually',
                style: TextStyle(color: AppColors.gold),
              ),
            ),
            const Text(
              'No barcode? Products work without one too.',
              style: TextStyle(
                color: AppColors.midGrey,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay({required this.scanLineAnimation});

  final Animation<double> scanLineAnimation;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        const inset = 24.0;
        final frameRect = Rect.fromLTWH(
          inset,
          inset,
          size.width - inset * 2,
          size.height - inset * 2,
        );

        return AnimatedBuilder(
          animation: scanLineAnimation,
          builder: (context, child) {
            final lineTop = frameRect.top +
                (frameRect.height - 2) * scanLineAnimation.value;

            return Stack(
              children: [
                CustomPaint(
                  size: size,
                  painter: _DimmedOverlayPainter(frameRect: frameRect),
                ),
                _CornerBrackets(rect: frameRect),
                Positioned(
                  left: frameRect.left,
                  right: size.width - frameRect.right,
                  top: lineTop,
                  child: Container(
                    height: 2,
                    color: AppColors.gold,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _DimmedOverlayPainter extends CustomPainter {
  _DimmedOverlayPainter({required this.frameRect});

  final Rect frameRect;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(frameRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DimmedOverlayPainter oldDelegate) {
    return oldDelegate.frameRect != frameRect;
  }
}

class _CornerBrackets extends StatelessWidget {
  const _CornerBrackets({required this.rect});

  final Rect rect;
  static const double _cornerSize = 20;
  static const double _thickness = 3;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _corner(top: rect.top, left: rect.left, isTop: true, isLeft: true),
        _corner(
          top: rect.top,
          left: rect.right - _cornerSize,
          isTop: true,
          isLeft: false,
        ),
        _corner(
          top: rect.bottom - _cornerSize,
          left: rect.left,
          isTop: false,
          isLeft: true,
        ),
        _corner(
          top: rect.bottom - _cornerSize,
          left: rect.right - _cornerSize,
          isTop: false,
          isLeft: false,
        ),
      ],
    );
  }

  Widget _corner({
    required double top,
    required double left,
    required bool isTop,
    required bool isLeft,
  }) {
    return Positioned(
      top: top,
      left: left,
      child: SizedBox(
        width: _cornerSize,
        height: _cornerSize,
        child: Stack(
          children: [
            Positioned(
              top: isTop ? 0 : null,
              bottom: isTop ? null : 0,
              left: isLeft ? 0 : null,
              right: isLeft ? null : 0,
              child: Container(
                width: _cornerSize,
                height: _thickness,
                color: AppColors.gold,
              ),
            ),
            Positioned(
              top: isTop ? 0 : null,
              bottom: isTop ? null : 0,
              left: isLeft ? 0 : null,
              right: isLeft ? null : 0,
              child: Container(
                width: _thickness,
                height: _cornerSize,
                color: AppColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Show the barcode scanner bottom sheet.
/// Returns the scanned barcode string or null if cancelled.
Future<String?> showBarcodeScanner(
  BuildContext context,
) async {
  return showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.82,
      child: const BarcodeScannerSheet(),
    ),
  );
}
