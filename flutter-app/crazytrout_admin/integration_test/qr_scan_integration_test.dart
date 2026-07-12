import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:crazytrout_admin/main.dart' as app;

/// Интеграционные тесты QR-сканера.
///
/// Запуск на эмуляторе/реальном устройстве:
///   flutter test integration_test/qr_scan_integration_test.dart
///
/// Требования:
///   - Камера (физ. устройство или эмулятор с поддержкой камеры)

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('QR-сканер — интеграционные тесты', () {
    testWidgets('открывается экран сканирования по нажатию иконки QR',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Находим иконку QR-сканера на экране чека
      final qrButton = find.byIcon(Icons.qr_code_scanner_rounded);
      expect(qrButton, findsOneWidget);

      // Нажимаем — должен открыться QrScanScreen
      await tester.tap(qrButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Проверяем что экран сканера открылся (AppBar с заголовком)
      expect(find.text('Скан QR клиента'), findsOneWidget);
    });

    testWidgets('кнопка фонарика переключает состояние', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Открываем сканер
      await tester.tap(find.byIcon(Icons.qr_code_scanner_rounded));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Кнопка фонарика — ищем flash_off (по умолчанию выключен)
      final torchOff = find.byIcon(Icons.flash_off);
      if (torchOff.evaluate().isNotEmpty) {
        await tester.tap(torchOff);
        await tester.pumpAndSettle();
        // После нажатия должен появиться flash_on
        expect(find.byIcon(Icons.flash_on), findsOneWidget);
      }
    });

    testWidgets('назад возвращает на экран чека', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Открываем сканер
      await tester.tap(find.byIcon(Icons.qr_code_scanner_rounded));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Нажимаем "назад"
      final back = find.byTooltip('Back');
      if (back.evaluate().isNotEmpty) {
        await tester.tap(back);
      } else {
        await tester.pageBack();
      }
      await tester.pumpAndSettle();

      // Должны вернуться на экран чека
      expect(find.text('Выставление чека'), findsOneWidget);
    });

    testWidgets(
        'при разрешении камеры — НЕ показывает сообщение "Нет доступа к камере"',
        (tester) async {
      // Регрессионный тест для бага "чёрный экран".
      // Если камера работает, не должно быть сообщения об ошибке.
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.qr_code_scanner_rounded));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Если permission granted — НЕ должно быть "Нет доступа к камере"
      final permissionDenied = find.text('Нет доступа к камере');
      expect(permissionDenied, findsNothing);
    });

    testWidgets(
        'при ошибке камеры — показывает сообщение, а НЕ чёрный экран',
        (tester) async {
      // Регрессионный тест для бага "чёрный экран".
      // Если камера не запустилась, должно быть видимое сообщение об ошибке.
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.qr_code_scanner_rounded));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Проверяем что есть хотя бы одна из:
      // - "Запуск камеры…" (placeholder, камера ещё стартует)
      // - "Камера недоступна" (error, камера не запустилась)
      // - "Нет доступа к камере" (permission denied)
      // - "Наведите камеру на QR-код" (камера работает)
      //
      // Если NONE из этих текстов нет — значит просто чёрный экран (баг).
      final hasLoading = find.text('Запуск камеры…').evaluate().isNotEmpty;
      final hasCameraError =
          find.text('Камера недоступна').evaluate().isNotEmpty;
      final hasPermissionDenied =
          find.text('Нет доступа к камере').evaluate().isNotEmpty;
      final hasHint = find
          .text('Наведите камеру на QR-код в профиле клиента')
          .evaluate()
          .isNotEmpty;

      expect(
        hasLoading || hasCameraError || hasPermissionDenied || hasHint,
        isTrue,
        reason:
            'Экран QR-сканера показывает чёрный экран без обратной связи. '
            'Ожидался текст: "Запуск камеры…", "Камера недоступна", '
            '"Нет доступа к камере" или "Наведите камеру на QR-код".',
      );
    });
  });
}
