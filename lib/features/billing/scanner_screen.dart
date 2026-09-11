import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key, required this.purpose});

  final ScanPurpose purpose;

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _controller;
  late final AnimationController _scanLine;
  DateTime? _lastScan;
  String? _lastCode;
  bool _handling = false;
  bool _torchOn = false;

  static const _barcodeFormats = <BarcodeFormat>[
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.upcA,
    BarcodeFormat.upcE,
    BarcodeFormat.code128,
    BarcodeFormat.code39,
    BarcodeFormat.code93,
    BarcodeFormat.codabar,
    BarcodeFormat.itf14,
    BarcodeFormat.itf2of5,
    BarcodeFormat.dataBar,
    BarcodeFormat.dataBarExpanded,
    BarcodeFormat.dataBarLimited,
  ];

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      formats: _barcodeFormats,
      facing: CameraFacing.back,
    );
    _scanLine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanLine.dispose();
    _controller.dispose();
    super.dispose();
  }

  Rect _barcodeWindow(Size size) {
    final width = size.width * 0.86;
    final height = 128.0;
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: width,
      height: height,
    );
  }

  Future<void> _onCode(String code) async {
    if (_handling) return;
    final now = DateTime.now();
    if (_lastCode == code &&
        _lastScan != null &&
        now.difference(_lastScan!) < const Duration(milliseconds: 900)) {
      return;
    }
    _lastCode = code;
    _lastScan = now;
    _handling = true;

    if (widget.purpose == ScanPurpose.captureBarcode) {
      if (mounted) context.pop(code);
      _handling = false;
      return;
    }

    final product = await ref
        .read(productRepositoryProvider)
        .getProductByBarcode(code);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    if (product == null) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.barcode_reader,
                  color: scheme.onErrorContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.scannerNotFoundTitle)),
            ],
          ),
          content: Text(l10n.scannerNotFoundBody(code)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                this.context.push('/products/edit?barcode=$code');
              },
              child: Text(l10n.scannerAddProduct),
            ),
          ],
        ),
      );
      _handling = false;
      return;
    }

    switch (widget.purpose) {
      case ScanPurpose.addToCart:
        ref.read(cartProvider.notifier).addProduct(product, barcode: code);
        if (mounted) context.pop();
      case ScanPurpose.lookup:
        if (mounted) context.pushReplacement('/products/edit?id=${product.id}');
      case ScanPurpose.stockIn:
        if (mounted) context.pop(product);
      case ScanPurpose.captureBarcode:
        if (mounted) context.pop(code);
    }
    _handling = false;
  }

  Future<void> _enterManual() async {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.barcode_reader, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.scannerEnterManual)),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.visiblePassword,
          decoration: InputDecoration(
            hintText: l10n.productsBarcode,
            prefixIcon: const Icon(Icons.view_week_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.commonContinue),
          ),
        ],
      ),
    );
    if (code != null && code.isNotEmpty) await _onCode(code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final value = capture.barcodes.firstOrNull?.rawValue;
              if (value != null) _onCode(value);
            },
          ),
          AnimatedBuilder(
            animation: _scanLine,
            builder: (context, _) {
              return CustomPaint(
                painter: _BarcodeOverlayPainter(
                  windowBuilder: _barcodeWindow,
                  accent: scheme.primary,
                  scanProgress: _scanLine.value,
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  _CircleAction(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.pop(),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.view_week_rounded,
                          color: scheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.scannerTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _CircleAction(
                    icon: _torchOn
                        ? Icons.flashlight_on_rounded
                        : Icons.flashlight_off_rounded,
                    onTap: () async {
                      await _controller.toggleTorch();
                      if (!mounted) return;
                      setState(() => _torchOn = !_torchOn);
                    },
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.view_week_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 28,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.scannerAlign,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.barcode_reader,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Align the barcode inside the frame',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _enterManual,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.keyboard_rounded),
                        label: Text(l10n.scannerEnterManual),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _BarcodeOverlayPainter extends CustomPainter {
  const _BarcodeOverlayPainter({
    required this.windowBuilder,
    required this.accent,
    required this.scanProgress,
  });

  final Rect Function(Size size) windowBuilder;
  final Color accent;
  final double scanProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final window = windowBuilder(size);
    final overlay = Path()..addRect(Offset.zero & size);
    final cutout = Path()
      ..addRRect(
        RRect.fromRectAndRadius(window, const Radius.circular(16)),
      );
    final dimmed = Path.combine(PathOperation.difference, overlay, cutout);

    canvas.drawPath(
      dimmed,
      Paint()..color = Colors.black.withValues(alpha: 0.62),
    );

    // Soft barcode guide bars inside the window
    final guidePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 2;
    final barCount = 18;
    final gap = window.width / (barCount + 1);
    for (var i = 1; i <= barCount; i++) {
      final x = window.left + gap * i;
      final tall = i.isEven;
      final inset = tall ? 18.0 : 28.0;
      canvas.drawLine(
        Offset(x, window.top + inset),
        Offset(x, window.bottom - inset),
        guidePaint,
      );
    }

    // Corner brackets
    final cornerPaint = Paint()
      ..color = accent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const corner = 22.0;
    final left = window.left;
    final right = window.right;
    final top = window.top;
    final bottom = window.bottom;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + corner)
        ..lineTo(left, top)
        ..lineTo(left + corner, top),
      cornerPaint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(right - corner, top)
        ..lineTo(right, top)
        ..lineTo(right, top + corner),
      cornerPaint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(left, bottom - corner)
        ..lineTo(left, bottom)
        ..lineTo(left + corner, bottom),
      cornerPaint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(right - corner, bottom)
        ..lineTo(right, bottom)
        ..lineTo(right, bottom - corner),
      cornerPaint,
    );

    // Animated horizontal scan line
    final y = window.top + 10 + (window.height - 20) * scanProgress;
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          accent.withValues(alpha: 0),
          accent,
          accent.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(window.left, y - 1, window.width, 2));
    canvas.drawRect(
      Rect.fromLTWH(window.left + 8, y - 1.5, window.width - 16, 3),
      linePaint,
    );
    canvas.drawCircle(
      Offset(window.center.dx, y),
      3.5,
      Paint()..color = accent,
    );
  }

  @override
  bool shouldRepaint(covariant _BarcodeOverlayPainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress ||
        oldDelegate.accent != accent;
  }
}
