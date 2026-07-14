import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/screens/pond_map_filter_config.dart';
import 'package:crazytrout_admin/screens/pond_map_screen.dart';

/// Widget-тесты на FiltersDropdown.
///
/// Проверяют: кнопка отображает правильный текст, dropdown открывается/закрывается,
/// выбор варианта вызывает onChange.
void main() {
  group('FiltersDropdown', () {
    Widget buildApp({
      FilterValue value = FilterValue.none,
      ValueChanged<FilterValue>? onChange,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: FiltersDropdown(
              value: value,
              onChange: onChange ?? (_) {},
            ),
          ),
        ),
      );
    }

    testWidgets('кнопка отображает "Фильтры" по умолчанию', (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.text('Фильтры'), findsOneWidget);
    });

    testWidgets('кнопка отображает "Все" при FilterValue.all', (tester) async {
      await tester.pumpWidget(buildApp(value: FilterValue.all));
      expect(find.text('Все'), findsOneWidget);
    });

    testWidgets('кнопка отображает "Премиум" при FilterValue.premium', (tester) async {
      await tester.pumpWidget(buildApp(value: FilterValue.premium));
      expect(find.text('Премиум'), findsOneWidget);
    });

    testWidgets('тап по кнопке открывает dropdown с вариантами', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Фильтры'));
      await tester.pump();

      // Должны появиться все варианты в overlay
      expect(find.text('Нет'), findsOneWidget);
      expect(find.text('Все клиенты'), findsOneWidget);
      expect(find.text('Премиум'), findsOneWidget);
      expect(find.text('Стандарт'), findsOneWidget);
      expect(find.text('Базовый'), findsOneWidget);
    });

    testWidgets('выбор варианта вызывает onChange', (tester) async {
      FilterValue? selected;
      await tester.pumpWidget(buildApp(onChange: (v) => selected = v));
      await tester.tap(find.text('Фильтры'));
      await tester.pump();

      await tester.tap(find.text('Премиум'));
      await tester.pump();

      expect(selected, FilterValue.premium);
    });
  });
}
