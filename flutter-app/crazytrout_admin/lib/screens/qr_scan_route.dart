import 'package:flutter/material.dart';
import 'qr_scan_screen.dart';

/// Отложенная загрузка маршрута QR-сканера.
///
/// Используется deferred-импорт, чтобы receipt_screen.dart не тянул
/// qr_code_scanner (platform plugin) в цепочку компиляции тестов.
final Route<String> Function() createQrScanRoute = () {
  return MaterialPageRoute<String>(
    builder: (_) => const QrScanScreen(),
  );
};
