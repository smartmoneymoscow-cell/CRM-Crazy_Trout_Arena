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
      expect(find.text('P&L'), findsOneWidget);
      expect(find.text('Профиль'), findsOneWidget);
    });

    testWidgets('экран чека содержит заголовок', (WidgetTester tester) async {
      await tester.pumpWidget(const CrazyTroutAdminApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Выставление чека'), findsOneWidget);
    });

    testWidgets('поиск клиента и QR-кнопка присутствуют', (WidgetTester tester) async {
      await tester.pumpWidget(const CrazyTroutAdminApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Поиск по имени или телефону…'), findsOneWidget);
      expect(find.byTooltip('Сканировать QR клиента'), findsOneWidget);
    });

    testWidgets('кнопка "Гость" и "Добавить рыбу" присутствуют', (WidgetTester tester) async {
      await tester.pumpWidget(const CrazyTroutAdminApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Гость · без анкеты'), findsOneWidget);
      expect(find.text('+ Добавить рыбу'), findsOneWidget);
    });

    testWidgets('кнопка печати видна после скролла вниз', (WidgetTester tester) async {
      await tester.pumpWidget(const CrazyTroutAdminApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      // Кнопка «Создать и распечатать чек» внизу ListView — скроллим к ней
      await tester.scrollUntilVisible(
        find.text('Создать и распечатать чек'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Создать и распечатать чек'), findsOneWidget);
    });
  });
}
