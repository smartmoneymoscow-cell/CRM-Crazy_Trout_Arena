import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// Импортируем ОРИГИНАЛЬНУЮ версию QrScanScreen (до фикса)
import '_qr_scan_screen_original.dart';

/// Тест регрессии: проверяем что ОРИГИНАЛЬНАЯ версия QrScanScreen
/// не передаёт errorBuilder/placeholderBuilder в MobileScanner.
///
/// MobileScanner — платформенный плагин, поэтому pumpWidget не используем.
/// Проверяем только что виджет создаётся (smoke).
///
/// Полная проверка что фикс работает → integration_test/

void main() {
  group('REGRESSION: оригинальная версия QrScanScreen', () {
    test('конструктор создаёт StatefulWidget (smoke)', () {
      const widget = QrScanScreenOriginal();
      expect(widget, isA<StatefulWidget>());
    });
  });
}
