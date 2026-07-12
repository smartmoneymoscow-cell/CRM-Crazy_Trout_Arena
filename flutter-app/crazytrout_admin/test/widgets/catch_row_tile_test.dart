import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/models/catch_row.dart';
import 'package:crazytrout_admin/widgets/catch_row_tile.dart';

void main() {
  group('CatchRowTile — виджет строки улова', () {
    testWidgets('отображает поля кг и грамм пустыми по умолчанию', (WidgetTester tester) async {
      final row = CatchRow(id: 1, species: 'Карп', kg: 0, grams: 0, pricePerKg: 590);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: CatchRowTile(
          row: row,
          onChanged: () {},
          onRemove: () {},
        )),
      ));
      // Поля пустые — "0" не отображается
      expect(find.text('0'), findsNothing);
    });

    testWidgets('отображает породу в dropdown', (WidgetTester tester) async {
      final row = CatchRow(id: 1, species: 'Карп', kg: 0, grams: 0, pricePerKg: 590);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: CatchRowTile(
          row: row,
          onChanged: () {},
          onRemove: () {},
        )),
      ));
      expect(find.text('Карп'), findsOneWidget);
    });

    testWidgets('кнопка удаления вызывает onRemove', (WidgetTester tester) async {
      bool removed = false;
      final row = CatchRow(id: 1, species: 'Карп', kg: 0, grams: 0, pricePerKg: 590);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: CatchRowTile(
          row: row,
          onChanged: () {},
          onRemove: () => removed = true,
        )),
      ));
      await tester.tap(find.byIcon(Icons.close));
      expect(removed, isTrue);
    });

    testWidgets('отображает сумму "0 ₽" для пустого улова', (WidgetTester tester) async {
      final row = CatchRow(id: 1, species: 'Карп', kg: 0, grams: 0, pricePerKg: 590);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: CatchRowTile(
          row: row,
          onChanged: () {},
          onRemove: () {},
        )),
      ));
      expect(find.text('0 ₽'), findsOneWidget);
    });

    testWidgets('отображает сумму "1 180 ₽" для 2кг × 590₽', (WidgetTester tester) async {
      final row = CatchRow(id: 1, species: 'Карп', kg: 2, grams: 0, pricePerKg: 590);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: CatchRowTile(
          row: row,
          onChanged: () {},
          onRemove: () {},
        )),
      ));
      expect(find.text('1 180 ₽'), findsOneWidget);
    });

    testWidgets('леблы ПОРОДА / КГ / ГРАММ / СУММА отображаются', (WidgetTester tester) async {
      final row = CatchRow(id: 1, species: 'Карп', kg: 0, grams: 0, pricePerKg: 590);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: CatchRowTile(
          row: row,
          onChanged: () {},
          onRemove: () {},
        )),
      ));
      expect(find.text('ПОРОДА'), findsOneWidget);
      expect(find.text('КГ'), findsOneWidget);
      expect(find.text('ГРАММ'), findsOneWidget);
      expect(find.text('СУММА'), findsOneWidget);
    });
  });
}
