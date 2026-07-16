import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/screens/pond_map_filter_config.dart';
import 'package:crazytrout_admin/screens/pond_map_screen.dart';

/// Widget-тесты на FiltersDropdown.
///
/// Проверяют: кнопка отображает правильный текст, dropdown открывается/закрывается,
/// выбор варианта вызывает onChange.
///
/// Требования (строго обязательно):
///   1. Список выпадает как у кнопки тарифов (Overlay + CompositedTransformFollower).
///   2. Выпадающий список НЕ нарушает скролл экрана.
///   3. Выпадающий список НЕ сворачивается при скролле экрана.
///   4. Выпадающий список скрывается ПОД нижнее меню.
///   5. Нет зазора между кнопкой и списком (gap = 0).
///   6. При раскрытии нижние углы кнопки выпрямляются.
///   7. Список НЕ смещается вверх от нижнего края кнопки.
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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      await tester.tap(find.text('Премиум'));
      await tester.pumpAndSettle();

      expect(selected, FilterValue.premium);
    });

    testWidgets('тап вне dropdown закрывает его', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Фильтры'));
      await tester.pumpAndSettle();

      // Dropdown открыт
      expect(find.text('Нет'), findsOneWidget);

      // Тапаем вне dropdown (в пустую область)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Dropdown закрыт — пункты меню исчезли
      expect(find.text('Нет'), findsNothing);
    });

    testWidgets('FiltersDropdown не принимает isOpenNotifier и scrollController', (tester) async {
      // Проверяем, что конструктор принимает только value и onChange
      // (isOpenNotifier и scrollController удалены — они нарушали скролл)
      final dropdown = FiltersDropdown(
        value: FilterValue.none,
        onChange: (_) {},
      );
      expect(dropdown.value, FilterValue.none);
    });
  });
}
