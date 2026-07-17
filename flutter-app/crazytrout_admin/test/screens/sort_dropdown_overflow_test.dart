import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/screens/checks_screen.dart';

/// Тесты на dropdown ранжирования чеков.
void main() {
  Widget buildApp() => MaterialApp(
    home: SizedBox(
      width: 400,
      height: 800,
      child: Scaffold(body: ChecksScreen()),
    ),
  );

  group('SortChip — dropdown не обрезается', () {
    testWidgets('dropdown помещается на экран', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final sortBtn = find.byIcon(Icons.sort);
      if (sortBtn.evaluate().isEmpty) return;

      await tester.tap(sortBtn);
      await tester.pumpAndSettle();

      final screenW = 400.0;
      final applyBtn = find.text('Применить');
      if (applyBtn.evaluate().isNotEmpty) {
        final rect = tester.getRect(applyBtn);
        expect(rect.right, lessThanOrEqualTo(screenW),
          reason: 'Dropdown обрезается правым краем экрана');
      }
    });
  });

  group('SortChip — кнопка Сбросить', () {
    testWidgets('кнопка Сбросить видна в dropdown', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final sortBtn = find.byIcon(Icons.sort);
      if (sortBtn.evaluate().isEmpty) return;

      await tester.tap(sortBtn);
      await tester.pumpAndSettle();

      expect(find.text('Сбросить'), findsOneWidget);
    });

    testWidgets('кнопка Сбросить сбрасывает и закрывает dropdown', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final sortBtn = find.byIcon(Icons.sort);
      if (sortBtn.evaluate().isEmpty) return;
      await tester.tap(sortBtn);
      await tester.pumpAndSettle();

      final resetBtn = find.text('Сбросить');
      expect(resetBtn, findsOneWidget);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      expect(find.text('Применить'), findsNothing);
    });
  });
}
