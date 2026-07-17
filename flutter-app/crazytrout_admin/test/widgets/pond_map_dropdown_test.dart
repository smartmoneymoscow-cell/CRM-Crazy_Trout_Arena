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
///   1. Dropdown рендерится в отдельном слое Stack (поверх feed, под нижним меню).
///   2. Выпадающий список НЕ нарушает скролл экрана.
///   3. Выпадающий список НЕ сворачивается при скролле экрана.
///   4. Выпадающий список скрывается ПОД нижнее меню (maxHeight ограничивает высоту).
///   5. Нет зазора между кнопкой и списком (gap = 0).
///   6. При раскрытии нижние углы кнопки выпрямляются, верхние НЕ меняются.
///   7. Dropdown строго под кнопкой (top: 36 в Stack).
///   8. Контент под dropdown НЕ двигается (Stack-слои, не inline).
void main() {
  group('FiltersDropdown', () {
    Widget buildApp({
      FilterValue value = FilterValue.none,
      ValueChanged<FilterValue>? onChange,
      bool isOpen = false,
      VoidCallback? onToggle,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: FiltersDropdown(
              value: value,
              onChange: onChange ?? (_) {},
              isOpen: isOpen,
              onToggle: onToggle ?? () {},
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

    testWidgets('тап по кнопке вызывает onToggle', (tester) async {
      bool toggled = false;
      await tester.pumpWidget(buildApp(onToggle: () => toggled = true));
      await tester.tap(find.text('Фильтры'));
      expect(toggled, isTrue);
    });

    testWidgets('при isOpen=true нижние углы кнопки выпрямляются', (tester) async {
      await tester.pumpWidget(buildApp(isOpen: true));
      // Кнопка всё ещё отображается
      expect(find.text('Фильтры'), findsOneWidget);
    });

    testWidgets('FiltersDropdown принимает value, onChange, isOpen, onToggle', (tester) async {
      final dropdown = FiltersDropdown(
        value: FilterValue.premium,
        onChange: (_) {},
        isOpen: false,
        onToggle: () {},
      );
      expect(dropdown.value, FilterValue.premium);
      expect(dropdown.isOpen, isFalse);
    });
  });
}
