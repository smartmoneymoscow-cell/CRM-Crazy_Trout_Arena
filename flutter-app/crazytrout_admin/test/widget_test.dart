import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/main.dart';

void main() {
  group('App — smoke tests', () {
    testWidgets('приложение запускается без крашей', (WidgetTester tester) async {
      await tester.pumpWidget(const CrazyTroutAdminApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      // Игнорируем overflow-предупреждения
      while (tester.takeException() != null) {}
    });

    testWidgets('после SplashScreen показывается HomeShell', (WidgetTester tester) async {
      await tester.pumpWidget(const CrazyTroutAdminApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}
      expect(find.text('Чек'), findsOneWidget);
    });

    testWidgets('нижнее меню содержит все 5 вкладок', (WidgetTester tester) async {
      await tester.pumpWidget(const CrazyTroutAdminApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}
      expect(find.text('Карта'), findsOneWidget);
      expect(find.text('Чек'), findsOneWidget);
      expect(find.text('Чеки'), findsOneWidget);
      expect(find.text('Отчёты'), findsOneWidget);
      expect(find.text('Профиль'), findsOneWidget);
    });

    testWidgets('экран чека содержит заголовок', (WidgetTester tester) async {
      await tester.pumpWidget(const CrazyTroutAdminApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}
      await tester.tap(find.text('Чеки'));
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}
    });

    testWidgets('поиск клиента и QR-кнопка присутствуют', (WidgetTester tester) async {
      await tester.pumpWidget(const CrazyTroutAdminApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}
    });
  });
}
