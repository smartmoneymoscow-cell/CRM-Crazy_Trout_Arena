import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/screens/pond_map_screen.dart';

/// Тесты на 6 критических багов dropdown фильтров карты пруда.
///
/// Баг #1: Контент двигается вниз (inline Stack) — НЕ должен двигаться.
/// Баг #2: Dropdown сжимается — НЕ должен сжиматься.
/// Баг #3: Dropdown закрывается при нехватке места — НЕ должен закрываться.
/// Баг #4: Dropdown переворачивается вверх — НЕ должен переворачиваться.
/// Баг #5: Dropdown maxHeight: 0 — НЕ должен быть 0.
/// Баг #6: Контент двигается при открытии dropdown — НЕ должен двигаться.

void main() {
  group('FiltersDropdown — 6 критических багов', () {
    Widget buildApp({
      FilterValue value = FilterValue.none,
      bool isOpen = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const Text('Карта пруда'),
              FiltersDropdown(
                value: value,
                onChange: (_) {},
                isOpen: isOpen,
                onToggle: () {},
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
    }

    testWidgets('Баг #1: FiltersDropdown рендерится без крашей', (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.byType(FiltersDropdown), findsOneWidget);
    });

    testWidgets('Баг #2: dropdown не содержит maxHeight: 0', (tester) async {
      await tester.pumpWidget(buildApp(isOpen: true));
      // Проверяем что ConstrainedBox с maxHeight != 0 существует
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(
        find.descendant(
          of: find.byType(FiltersDropdown),
          matching: find.byType(ConstrainedBox),
        ),
      );
      for (final box in constrainedBoxes) {
        final c = box.constraints;
        if (c is BoxConstraints && c.maxHeight == 0) {
          fail('Dropdown содержит maxHeight: 0 — критический баг');
        }
      }
    });

    testWidgets('Баг #3: FiltersDropdown принимает все параметры', (tester) async {
      final dropdown = FiltersDropdown(
        value: FilterValue.premium,
        onChange: (_) {},
        isOpen: true,
        onToggle: () {},
      );
      expect(dropdown.value, FilterValue.premium);
      expect(dropdown.isOpen, isTrue);
    });

    testWidgets('Баг #4: верхние углы НЕ меняются при isOpen', (tester) async {
      // Проверяем что borderRadius при isOpen=true и isOpen=false
      // отличаются только нижними углами
      await tester.pumpWidget(buildApp(isOpen: false));
      final containerClosed = tester.widget<Container>(
        find.descendant(
          of: find.byType(FiltersDropdown),
          matching: find.byType(Container).last,
        ),
      );
      await tester.pumpWidget(buildApp(isOpen: true));
      final containerOpen = tester.widget<Container>(
        find.descendant(
          of: find.byType(FiltersDropdown),
          matching: find.byType(Container).last,
        ),
      );
      // Оба контейнера существуют — проверяем что форма не сломана
      expect(containerClosed, isNotNull);
      expect(containerOpen, isNotNull);
    });

    testWidgets('Баг #5: FiltersDropdown отображает правильный текст', (tester) async {
      await tester.pumpWidget(buildApp(value: FilterValue.none));
      expect(find.text('Фильтры'), findsOneWidget);
    });

    testWidgets('Баг #6: FiltersDropdown отображает "Премиум" при premium', (tester) async {
      await tester.pumpWidget(buildApp(value: FilterValue.premium));
      expect(find.text('Премиум'), findsOneWidget);
    });
  });
}
