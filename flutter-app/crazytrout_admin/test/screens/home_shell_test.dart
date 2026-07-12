import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/screens/home_shell.dart';

void main() {
  group('HomeShell — нижняя навигация', () {
    testWidgets('отображает 5 вкладок', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeShell()));
      await tester.pump();
      expect(find.byType(NavigationDestination), findsNWidgets(5));
    });

    testWidgets('по умолчанию выбрана вкладка "Чек" (индекс 1)', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeShell()));
      await tester.pump();
      // Чек — активная вкладка, ReceiptScreen показывается
      expect(find.text('Выставление чека'), findsOneWidget);
    });

    testWidgets('переключение на "Карта" показывает заглушку', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeShell()));
      await tester.pump();
      await tester.tap(find.text('Карта'));
      await tester.pumpAndSettle();
      expect(find.text('Карта прудов и точек лова — раздел в разработке.'), findsOneWidget);
    });

    testWidgets('переключение на "Чеки" показывает заглушку', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeShell()));
      await tester.pump();
      await tester.tap(find.text('Чеки'));
      await tester.pumpAndSettle();
      expect(find.text('История выставленных чеков — раздел в разработке.'), findsOneWidget);
    });

    testWidgets('переключение на "P&L" показывает заглушку', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeShell()));
      await tester.pump();
      await tester.tap(find.text('P&L'));
      await tester.pumpAndSettle();
      expect(find.text('Отчёт по прибыли и убыткам — раздел в разработке.'), findsOneWidget);
    });

    testWidgets('переключение на "Профиль" показывает заглушку', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeShell()));
      await tester.pump();
      await tester.tap(find.text('Профиль'));
      await tester.pumpAndSettle();
      expect(find.text('Профиль администратора — раздел в разработке.'), findsOneWidget);
    });

    testWidgets('возврат на "Чек" показывает форму', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeShell()));
      await tester.pump();
      // Уходим на другую вкладку
      await tester.tap(find.text('Карта'));
      await tester.pumpAndSettle();
      // Возвращаемся
      await tester.tap(find.text('Чек'));
      await tester.pumpAndSettle();
      expect(find.text('Выставление чека'), findsOneWidget);
    });

    testWidgets('NavigationBar высотой 64px', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeShell()));
      await tester.pump();
      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      // NavigationBar обёрнут в SizedBox(height: 64)
      final sizedBox = tester.widget<SizedBox>(find.ancestor(
        of: find.byType(NavigationBar),
        matching: find.byType(SizedBox),
      ).first);
      expect(sizedBox.height, 64);
    });
  });
}
