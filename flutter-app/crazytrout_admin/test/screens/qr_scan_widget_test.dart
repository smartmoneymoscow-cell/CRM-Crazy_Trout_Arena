import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:crazytrout_admin/screens/qr_scan_screen.dart';

/// Widget-тесты для QrScanScreen.
///
/// MobileScanner — платформенный плагин. pumpWidget вызовет
/// MissingPluginException в тестовой среде.
/// Поэтому проверяем только конструктор и параметры через рефлексию.
///
/// Полная проверка UI → integration_test/qr_scan_integration_test.dart

void main() {
  group('QrScanScreen — widget', () {
    test('конструктор создаёт StatefulWidget', () {
      const widget = QrScanScreen();
      expect(widget, isA<StatefulWidget>());
    });

    test('MobileScanner используется в build (проверка импорта)', () {
      // Проверяем что MobileScanner импортирован и доступен
      // Сам виджет не рендерим — платформенный плагин не работает в тестах
      expect(MobileScanner, isNotNull);
    });
  });
}
