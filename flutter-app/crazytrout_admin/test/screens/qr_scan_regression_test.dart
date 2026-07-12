import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// Импортируем ОРИГИНАЛЬНУЮ версию QrScanScreen (до фикса)
import '_qr_scan_screen_original.dart';

/// Тест регрессии: проверяем что ОРИГИНАЛЬНАЯ версия QrScanScreen
/// проваливает тест на наличие errorBuilder/placeholderBuilder.
///
/// Если этот тест ПРОХОДИТ на оригинальной версии — значит тест не работает.
/// Если ПРОВАЛИВАЕТСЯ — значит тест корректно находит баг "чёрный экран".

void main() {
  group('REGRESSION: оригинальная версия QrScanScreen (баг "чёрный экран")', () {
    testWidgets(
        'FAIL = баг найден: MobileScanner НЕ имеет errorBuilder',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: QrScanScreenOriginal(),
        ),
      );

      final mobileScannerWidget =
          tester.widget<MobileScanner>(find.byType(MobileScanner));

      // В оригинальной версии errorBuilder == null → чёрный экран при ошибке
      // Тест ДОЛЖЕН ПРОВАЛИТЬСЯ на оригинальной версии.
      expect(
        mobileScannerWidget.errorBuilder,
        isNotNull,
        reason:
            'БАГ НАЙДЕН: MobileScanner.errorBuilder == null. '
            'При ошибке камеры будет чёрный экран без обратной связи.',
      );
    });

    testWidgets(
        'FAIL = баг найден: MobileScanner НЕ имеет placeholderBuilder',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: QrScanScreenOriginal(),
        ),
      );

      final mobileScannerWidget =
          tester.widget<MobileScanner>(find.byType(MobileScanner));

      // В оригинальной версии placeholderBuilder == null → чёрный экран при загрузке
      // Тест ДОЛЖЕН ПРОВАЛИТЬСЯ на оригинальной версии.
      expect(
        mobileScannerWidget.placeholderBuilder,
        isNotNull,
        reason:
            'БАГ НАЙДЕН: MobileScanner.placeholderBuilder == null. '
            'Пока камера инициализируется — чёрный экран без индикатора.',
      );
    });
  });
}
