import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// ОРИГИНАЛЬНАЯ версия QrScanScreen (до фикса) — для проверки тестов.
/// Этот файл НЕ входит в сборку, только для тестирования регрессии.
class QrScanScreenOriginal extends StatefulWidget {
  const QrScanScreenOriginal({super.key});

  @override
  State<QrScanScreenOriginal> createState() => _QrScanScreenOriginalState();
}

class _QrScanScreenOriginalState extends State<QrScanScreenOriginal> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  bool _torchOn = false;
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;
    _handled = true;
    Navigator.of(context).pop(raw);
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Скан QR клиента'),
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleTorch,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // БЕЗ errorBuilder и placeholderBuilder — это и был баг
          MobileScanner(controller: _controller, onDetect: _onDetect),
          const _ScanFrameOverlay(),
          const Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Text(
              'Наведите камеру на QR-код в профиле клиента',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanFrameOverlay extends StatelessWidget {
  const _ScanFrameOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE89829), width: 3),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
