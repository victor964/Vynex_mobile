// Modal bottom sheet with camera barcode scanner.
// Returns the scanned barcode string via Navigator.pop()
// or null if the user cancels without scanning.

import 'dart:async';

import 'package:flutter/foundation.dart';
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _torchOn = false;
  bool _isProcessing = false;
  bool _isStarting = false;
  bool _hasError = false;
  String _errorMessage = '';
  late MobileScannerController _controller;
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 400), _startCamera);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanLineController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _startCamera();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(_controller.stop());
    }
  }

  Future<void> _startCamera() async {
    if (!mounted || _isStarting) return;
    _isStarting = true;

    try {
      if (_controller.value.isRunning) {
        await _controller.stop();
      }
      await _controller.start();
    } on MobileScannerException catch (error) {
      if (kDebugMode) {
        debugPrint('Barcode scanner start error: ${error.errorCode}');
      }
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = _getReadableError(error);
        });
      }
    } finally {
      _isStarting = false;
    }
  }

  Future<void> _retryCamera() async {
    if (!mounted) return;
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _isProcessing = false;
    });
    try {
      await _controller.stop();
      await _controller.start();
    } on MobileScannerException catch (error) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = _getReadableError(error);
        });
      }
    }
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

  String _getReadableError(MobileScannerException error) {
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Camera permission was denied. '
            'Go to Settings and allow camera access '
            'for Vynex.';
      case MobileScannerErrorCode.unsupported:
        return 'Barcode scanning is not supported '
            'on this device.';
      case MobileScannerErrorCode.genericError:
      default:
        return 'Camera could not start. '
            'Try closing other camera apps first.';
    }
  }

  Widget _buildCameraError() {
    return Container(
      color: AppColors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off_rounded,
                color: AppColors.midGrey,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Camera unavailable',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage.isNotEmpty
                    ? _errorMessage
                    : 'Could not start the camera. '
                      'Please check camera permission '
                      'in your phone settings.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.midGrey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _retryCamera,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text(
                  'Type barcode manually instead',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return const ColoredBox(
      color: AppColors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.gold),
            SizedBox(height: 12),
            Text(
              'Starting camera...',
              style: TextStyle(
                color: AppColors.midGrey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
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
                    child: _hasError
                        ? _buildCameraError()
                        : MobileScanner(
                            controller: _controller,
                            fit: BoxFit.cover,
                            useAppLifecycleState: false,
                            onDetect: _onDetect,
                            placeholderBuilder: _buildPlaceholder,
                            errorBuilder: (context, error) {
                              WidgetsBinding.instance
                                  .addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _hasError = true;
                                    _errorMessage =
                                        _getReadableError(error);
                                  });
                                }
                              });
                              return _buildCameraError();
                            },
                            overlayBuilder: (context, constraints) {
                              return _ScanOverlay(
                                scanLineAnimation: _scanLineAnimation,
                                size: constraints.biggest,
                              );
                            },
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
  const _ScanOverlay({
    required this.scanLineAnimation,
    required this.size,
  });

  final Animation<double> scanLineAnimation;
  final Size size;

  @override
  Widget build(BuildContext context) {
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
        final lineTop =
            frameRect.top + (frameRect.height - 2) * scanLineAnimation.value;

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
    enableDrag: false,
    builder: (context) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.82,
      child: const BarcodeScannerSheet(),
    ),
  );
}
