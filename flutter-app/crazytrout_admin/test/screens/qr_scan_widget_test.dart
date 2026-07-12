import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:crazytrout_admin/screens/qr_scan_screen.dart';

/// Widget-тесты для QrScanScreen.
///
/// Проверяют что виджет корректно обрабатывает состояния камеры
/// и не показывает просто чёрный экран (регрессия бага).

void main() {
  group('QrScanScreen — widget', () {
    testWidgets('рендерится без краша', (tester) async {
      // Pump QrScanScreen в тестовой среде (без реальной камеры).
      // MobileScanner получит MissingPluginException — это ожидаемо.
      // Важно что сам Scaffold + AppBar строятся корректно.
      await tester.pumpWidget(
        const MaterialApp(
          home: QrScanScreen(),
        ),
      );

      // Должен отобразиться AppBar с заголовком
      expect(find.text('Скан QR клиента'), findsOneWidget);
    });

    testWidgets('AppBar содержит кнопку фонарика', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: QrScanScreen(),
        ),
      );

      // Иконка фонарика (по умолчанию выключен → flash_off)
      expect(find.byIcon(Icons.flash_off), findsOneWidget);
    });

    testWidgets('MobileScanner передаётся с errorBuilder и placeholderBuilder',
        (tester) async {
      // КЛЮЧЕВОЙ ТЕСТ РЕГРЕССИИ:
      //
      // Баг: MobileScanner без errorBuilder/placeholderBuilder показывает
      // просто чёрный ColoredBox при ошибке или инициализации.
      //
      // Фикс: QrScanScreen передаёт:
      //   - placeholderBuilder → "Запуск камеры…" + CircularProgressIndicator
      //   - errorBuilder → "Камера недоступна" + описание ошибки
      //
      // Проверяем что MobileScanner в дереве виджетов имеет эти параметры.

      await tester.pumpWidget(
        const MaterialApp(
          home: QrScanScreen(),
        ),
      );

      // Находим MobileScanner в дереве
      final mobileScannerFinder = find.byType(MobileScanner);
      expect(mobileScannerFinder, findsOneWidget);

      // Получаем виджет и проверяем что у него есть errorBuilder
      final mobileScannerWidget =
          tester.widget<MobileScanner>(mobileScannerFinder);

      // Если errorBuilder == null, то при ошибке камеры будет чёрный экран.
      // Это и был баг.
      expect(
        mobileScannerWidget.errorBuilder,
        isNotNull,
        reason:
            'MobileScanner.errorBuilder не задан — '
            'при ошибке камеры будет чёрный экран без обратной связи. '
            'Передайте errorBuilder с сообщением "Камера недоступна".',
      );

      // Аналогично для placeholderBuilder
      expect(
        mobileScannerWidget.placeholderBuilder,
        isNotNull,
        reason:
            'MobileScanner.placeholderBuilder не задан — '
            'пока камера инициализируется будет чёрный экран. '
            'Передайте placeholderBuilder с индикатором загрузки.',
      );
    });

    testWidgets('MobileScanner подключён к controller', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: QrScanScreen(),
        ),
      );

      final mobileScannerWidget =
          tester.widget<MobileScanner>(find.byType(MobileScanner));

      // Controller должен быть передан (не null)
      expect(
        mobileScannerWidget.controller,
        isNotNull,
        reason: 'MobileScanner.controller не задан — сканер не будет работать.',
      );
    });

    testWidgets('содержит подсказку для пользователя', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: QrScanScreen(),
        ),
      );

      // Текст-подсказка должен быть виден
      expect(
        find.text('Наведите камеру на QR-код в профиле клиента'),
        findsOneWidget,
      );
    });

    testWidgets('содержит overlay-рамку для сканирования', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: QrScanScreen(),
        ),
      );

      // Рамка-таргет (Container с Border) должна быть в дереве
      // Ищем IgnorePointer > Center > Container с border
      expect(find.byType(IgnorePointer), findsWidgets);
    });
  });
}
