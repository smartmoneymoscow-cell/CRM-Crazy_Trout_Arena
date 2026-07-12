import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/screens/stub_screen.dart';

void main() {
  group('StubScreen — заглушка раздела', () {
    testWidgets('отображает заголовок', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: StubScreen(
          title: 'Карта',
          icon: Icons.map_outlined,
          note: 'Раздел в разработке.',
        )),
      ));
      expect(find.text('Карта'), findsOneWidget);
    });

    testWidgets('отображает описание', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: StubScreen(
          title: 'P&L',
          icon: Icons.show_chart,
          note: 'Отчёт по прибыли и убыткам — раздел в разработке.',
        )),
      ));
      expect(find.text('Отчёт по прибыли и убыткам — раздел в разработке.'), findsOneWidget);
    });

    testWidgets('отображает иконку', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: StubScreen(
          title: 'Профиль',
          icon: Icons.person_outline,
          note: 'Профиль администратора.',
        )),
      ));
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('иконка правильного размера', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: StubScreen(
          title: 'Тест',
          icon: Icons.star,
          note: 'Тестовое описание.',
        )),
      ));
      final icon = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(icon.size, 40);
    });

    testWidgets('разные заглушки не конфликтуют', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: StubScreen(
          title: 'Чеки',
          icon: Icons.receipt_long_outlined,
          note: 'История выставленных чеков.',
        )),
      ));
      expect(find.text('Чеки'), findsOneWidget);
      expect(find.text('История выставленных чеков.'), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    });
  });
}
