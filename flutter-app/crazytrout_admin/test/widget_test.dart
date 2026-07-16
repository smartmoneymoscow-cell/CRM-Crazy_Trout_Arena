import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/main.dart';

void main() {
  group('App — smoke tests', () {
    testWidgets('приложение запускается без крашей', (WidgetTester tester) async {
      await tester.pumpWidget(const CrazyTroutAdminApp());
      // SplashScreen — не крашится, pump завершает таймер
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });

    testWidgets('после SplashScreen показывается HomeShell', (WidgetTester tester) async {
      await tester.pumpWidget(const CrazyTroutAdminApp());
      // Ждём завершения SplashScreen (2 секунды + settle)
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Чек'), findsOneWidget);
    });

    testWidgets('нижнее меню содержит все 5 вкладок', (WidgetTester tester) async {
      await tester.pumpWidget(const CrazyTroutAdminApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Карта'), findsOneWidget);
      expect(find.text('Чек'), findsOneWidget);
      expect(find.text('Чеки'), findsOneWidget);
      expect(find.text('Отчёт'), findsOneWidget);
      expect(find.text('Профиль'), findsOneWidget);
    });

    testWidgets('экран чека содержит заголовок', (WidgetTester tester) async {
      await tester.pumpWidget(const CrazyTroutAdminApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      // Начальный экран — Карта, переходим на вкладку Чек
      await tester.tap(find.text('Чек'));
      await tester.pumpAndSettle();
      expect(find.text('Выставление чека'), findsOneWidget);
    });

    testWidgets('поиск клиента и QR-кнопка присутствуют', (WidgetTester tester) async {
      await tester.pumpWidget(const CrazyTroutAdminApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      // Начальный экран — Карта, переходим на вкладку Чек
      await tester.tap(find.text('Чек'));
      await tester.pumpAndSettle();
      expect(find.text('Поиск по имени или телефону…'), findsOneWidget);
      expect(find.byTooltip('Сканировать QR клиента'), findsOneWidget);
    });

    testWidgets('кнопка "Гость" и "Добавить рыбу" присутствуют', (WidgetTester tester) async {
      await tester.pumpWidget(const CrazyTroutAdminApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      // Начальный экран — Карта, переходим на вкладку Чек
      await tester.tap(find.text('Чек'));
      await tester.pumpAndSettle();
      expect(find.text('Гость · без анкеты'), findsOneWidget);
      expect(find.text('+ Добавить рыбу'), findsOneWidget);
    });

    testWidgets('кнопка печати видна после скролла вниз', (WidgetTester tester) async {
      await tester.pumpWidget(const CrazyTroutAdminApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      // Начальный экран — Карта, переходим на вкладку Чек
      await tester.tap(find.text('Чек'));
      await tester.pumpAndSettle();

      // Кнопка «Создать и распечатать чек» находится внизу ListView
      // экрана чека. ListView-lazy не создаёт off-screen виджеты,
      // поэтому scrollUntilVisible не находит ListView в дереве.
      // Решение: ищем корневой Scrollable (ReceiptScreen → ListView)
      // через find.ancestor и скроллим вниз большими свайпами.
      final scrollable = find.ancestor(
        of: find.text('Выставление чека'),
        matching: find.byType(Scrollable),
      );
      expect(scrollable, findsOneWidget);

      // Скроллим вниз по 500px, пока кнопка не появится
      for (int i = 0; i < 6; i++) {
        if (find.text('Создать и распечатать чек').evaluate().isNotEmpty) break;
        await tester.drag(scrollable, const Offset(0, -500));
        await tester.pumpAndSettle();
      }
      expect(find.text('Создать и распечатать чек'), findsOneWidget);
    });
  });
}
