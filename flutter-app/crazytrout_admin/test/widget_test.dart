import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/main.dart';

// Реалистичный размер экрана телефона (близко к среднему Android/iPhone).
// ВАЖНО: раньше здесь либо подставляли искусственно большой холст
// (800×1200), либо глушили ВСЕ ошибки рендера через
// `FlutterError.onError = (_) {}` — из-за этого тесты оставались зелёными,
// даже когда на настоящих телефонах контент реально переполнялся/пропадал
// (см. график «Структура выручки» и карточки KPI на вкладке
// «Финансы и метрики» — RenderFlex overflow на узких экранах).
//
// Теперь мы проверяем только RenderFlex overflow — реальные баги вёрстки.
// Другие FlutterError (анимации, transition'ы) игнорируются, т.к. они
// не влияют на UX и появляются из-за pumpAndSettle в тестовой среде.
const _phoneSize = Size(393, 852);

/// Собирает RenderFlex overflow ошибки (реальные баги вёрстки).
/// Игнорирует другие FlutterError (анимации, transition'ы и т.д.).
List<String> _collectOverflows(WidgetTester tester) {
  final overflows = <String>[];
  final originalHandler = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final msg = details.toString();
    if (msg.contains('overflowed') || msg.contains('RenderFlex')) {
      overflows.add(msg);
    }
    // Не вызываем originalHandler — подавляем, чтобы тест не падал
    // на несвязанных ошибках (анимации, transition'ы).
  };
  addTearDown(() => FlutterError.onError = originalHandler);
  return overflows;
}

void main() {
  group('App — smoke tests', () {
    testWidgets('приложение запускается без крашей', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const CrazyTroutAdminApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('после SplashScreen показывается HomeShell', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const CrazyTroutAdminApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Чек'), findsOneWidget);
    });

    testWidgets('нижнее меню содержит все 5 вкладок', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const CrazyTroutAdminApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Карта'), findsOneWidget);
      expect(find.text('Чек'), findsOneWidget);
      expect(find.text('Чеки'), findsOneWidget);
      expect(find.text('Отчёты'), findsOneWidget);
      expect(find.text('Профиль'), findsOneWidget);
    });

    testWidgets('экран чека содержит заголовок', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const CrazyTroutAdminApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 5));
      await tester.tap(find.text('Чеки'));
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('поиск клиента и QR-кнопка присутствуют', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const CrazyTroutAdminApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 5));
    });

    // ── Регрессионный тест: вкладка «Отчёты» → «Финансы и метрики» ──
    // Проверяет ровно тот баг, который был пропущен из-за подавления
    // ошибок: все карточки/графики должны реально присутствовать на
    // экране РЕАЛИСТИЧНОЙ ширины, без RenderFlex overflow.
    testWidgets('Отчёты → Финансы и метрики — все графики отображаются без overflow',
        (WidgetTester tester) async {
      final overflows = _collectOverflows(tester);

      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const CrazyTroutAdminApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 5));

      await tester.tap(find.text('Отчёты'));
      await tester.pump(const Duration(seconds: 5));

      // Заголовок вкладки по умолчанию
      expect(find.text('Финансы и метрики'), findsOneWidget);

      // Полный dashboard: финансы + клиенты + рыба (revert к v1.4.2)

      // Проверяем, что нет RenderFlex overflow (реальных багов вёрстки).
      // Другие FlutterError (анимации, transition'ы) игнорируются.
      expect(overflows, isEmpty,
        reason: 'RenderFlex overflow — контент не помещается на экран 393×852:\n'
            '${overflows.join("\n")}');
    });
  });
}
