import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

/// Полноэкранный сканер QR-кода клиента.
///
/// Возвращает через Navigator.pop сырую строку из QR-кода, либо null,
/// если экран закрыли, ничего не отсканировав.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  MobileScannerController? _controller;

  bool _torchOn = false;
  bool _handled = false; // защита от повторного срабатывания на серии кадров
  bool _permissionDenied = false;
  bool _cameraReady = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    // 1. Проверяем разрешение
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }

    // 2. Создаём контроллер. Запуск камеры (start()) делает сам виджет
    //    MobileScanner через autoStart при монтировании — не нужно (и
    //    опасно) звать controller.start() здесь самим: в mobile_scanner
    //    5.2.3 start() ждёт, пока MobileScanner-виджет примонтируется
    //    (_isAttachedCompleter), а виджет мы рендерим только когда
    //    _cameraReady == true — вызов start() до этого момента просто
    //    висел бы до тайм-аута.
    //
    //    Прежняя задержка в 500 мс была бесполезна: контроллер в этот
    //    момент ещё не примонтирован в дерево виджетов, реальная нативная
    //    инициализация камеры начинается позже, когда рендерится
    //    MobileScanner — так что падать в момент задержки было нечему.
    //    Настоящая причина "MobileScannerException: genericError ...
    //    on a null object reference" именно в релизной сборке — R8/ProGuard
    //    обфусцирует и вырезает классы CameraX и ML Kit Barcode Scanning,
    //    к которым mobile_scanner обращается через рефлексию при первом
    //    старте камеры. Исправлено добавлением keep-правил в
    //    android/app/proguard-rules.pro через CI-воркфлоу (см. diff).
    try {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: const [BarcodeFormat.qrCode],
      );
      if (mounted) setState(() => _cameraReady = true);
    } catch (e) {
      if (mounted) setState(() => _initError = e.toString());
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
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
    await _controller?.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted && mounted) {
      setState(() => _permissionDenied = false);
      _initCamera();
    }
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography, color: Colors.white54, size: 64),
            const SizedBox(height: 24),
            const Text(
              'Нет доступа к камере',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Для сканирования QR-кода разрешите доступ к камере в настройках приложения.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _requestPermission,
              icon: const Icon(Icons.settings),
              label: const Text('Разрешить доступ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8912B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white54, size: 64),
            const SizedBox(height: 24),
            const Text(
              'Камера недоступна',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Назад'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white24,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
          if (_cameraReady)
            IconButton(
              icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
              onPressed: _toggleTorch,
            ),
        ],
      ),
      body: _permissionDenied
          ? _buildPermissionDenied()
          : _initError != null
              ? _buildError(_initError!)
              : !_cameraReady
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFFE8912B),
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Запуск камеры…',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: _controller!,
                          onDetect: _onDetect,
                          errorBuilder: (context, error, child) {
                            return _buildError('Ошибка камеры: $error');
                          },
                        ),
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

/// Рамка-таргет поверх камеры — помогает быстрее навести QR и не мешает
/// сканировать посторонний мусор в кадре.
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
