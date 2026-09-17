import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// A full-screen barcode scanner with flashlight and camera switch controls.
///
/// Returns the scanned barcode value via [Navigator.pop] when a valid code
/// is detected. Automatically prevents double-triggering when multiple frames read the same code.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  /// Local state to track torch ON/OFF
  bool _isTorchOn = false;

  /// Prevents the scanner from triggering multiple times when the camera
  /// reads the same barcode across consecutive frames.
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Handles barcode detection events from the camera stream.
  void _onDetect(BarcodeCapture capture) {
    // Guard: ignore if we're already processing a scan or widget is unmounted
    if (_isProcessing || !mounted) return;

    // Guard: ignore empty captures
    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final rawValue = barcode.rawValue;

    // Guard: ignore invalid/empty barcode values
    if (rawValue == null || rawValue.trim().isEmpty) return;

    // Lock processing to prevent double-triggering from multiple frames
    setState(() => _isProcessing = true);

    // Stop the camera before popping to prevent further detections
    _controller.stop();

    // Return the scanned value to the calling screen
    Navigator.of(context).pop(rawValue);
  }

  /// Toggle flashlight ON/OFF
  void _toggleTorch() {
    _controller.toggleTorch();
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
  }

  /// Switch between front and back camera
  void _switchCamera() {
    _controller.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // --- Camera Preview ---
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // --- Scanner Overlay (Viewfinder) ---
          CustomPaint(painter: _ScannerOverlayPainter()),

          // --- Top Bar (Close + Title) ---
          _buildTopBar(context),

          // --- Bottom Controls (Flash + Camera Switch) ---
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              // Close button
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 16),
              // Title
              const Expanded(
                child: Text(
                  'Scanner un code-barres',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Flashlight toggle (NOW USING LOCAL STATE)
              _ScannerControlButton(
                icon: _isTorchOn ? Icons.flash_on : Icons.flash_off,
                label: _isTorchOn ? 'Flash activé' : 'Flash',
                isActive: _isTorchOn,
                onPressed: _toggleTorch,
              ),

              // Camera switch
              _ScannerControlButton(
                icon: Icons.cameraswitch,
                label: 'Retourner',
                onPressed: _switchCamera,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A reusable control button for the scanner bottom bar.
class _ScannerControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  const _ScannerControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: 28),
          style: IconButton.styleFrom(
            backgroundColor: isActive
                ? const Color(0xFF1E40AF) // Primary Blue from our design system
                : Colors.black.withValues(alpha: 0.5),
            padding: const EdgeInsets.all(14),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Custom painter that draws a scanner viewfinder overlay with rounded corners.
///
/// Darkens the area outside the viewfinder and draws white corner brackets
/// to indicate the scanning area.
class _ScannerOverlayPainter extends CustomPainter {
  // Our Primary Blue from the design system
  static const Color _accentColor = Color(0xFF1E40AF);

  @override
  void paint(Canvas canvas, Size size) {
    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.75,
      height: size.width * 0.75, // Square viewfinder
    );

    // --- 1. Draw dark overlay with a hole for the scan area ---
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(20)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, backgroundPaint);

    // --- 2. Draw corner brackets ---
    final cornerPaint = Paint()
      ..color = _accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    const cornerLength = 36.0;
    const cornerRadius = 20.0;

    // Top-left corner
    canvas.drawLine(
      scanRect.topLeft + const Offset(0, cornerRadius),
      scanRect.topLeft + const Offset(0, cornerLength),
      cornerPaint,
    );
    canvas.drawLine(
      scanRect.topLeft + const Offset(cornerRadius, 0),
      scanRect.topLeft + const Offset(cornerLength, 0),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      scanRect.topRight + const Offset(0, cornerRadius),
      scanRect.topRight + const Offset(0, cornerLength),
      cornerPaint,
    );
    canvas.drawLine(
      scanRect.topRight + const Offset(-cornerRadius, 0),
      scanRect.topRight + const Offset(-cornerLength, 0),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      scanRect.bottomLeft + const Offset(0, -cornerRadius),
      scanRect.bottomLeft + const Offset(0, -cornerLength),
      cornerPaint,
    );
    canvas.drawLine(
      scanRect.bottomLeft + const Offset(cornerRadius, 0),
      scanRect.bottomLeft + const Offset(cornerLength, 0),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      scanRect.bottomRight + const Offset(0, -cornerRadius),
      scanRect.bottomRight + const Offset(0, -cornerLength),
      cornerPaint,
    );
    canvas.drawLine(
      scanRect.bottomRight + const Offset(-cornerRadius, 0),
      scanRect.bottomRight + const Offset(-cornerLength, 0),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// HELPER FUNCTION
// ---------------------------------------------------------------------------

/// Opens the barcode scanner and returns the scanned value.
///
/// Returns `null` if the user closes the scanner without scanning anything,
/// or if the scan fails.
///
/// **Usage:**
/// ```dart
/// final barcode = await openBarcodeScanner(context);
/// if (barcode != null) {
///   // Use the barcode (e.g., search for a product)
/// }
/// ```
Future<String?> openBarcodeScanner(BuildContext context) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => const BarcodeScannerScreen(),
      fullscreenDialog: true,
    ),
  );
}
