import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/widgets/filter_dropdown.dart';

/// Тесты на FilterDropdown.
///
/// Требования (AGENTS.md):
///   - Открывать — всегда, независимо от наличия места.
///   - Открывать всегда под кнопкой только вниз.
///   - При скролле — не сворачиваться, не сжиматься, скрываться под нижнее меню.

void main() {
  group('FilterDropdown', () {
    testWidgets('отображает label по умолчанию', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FilterDropdown<String>(
            value: null,
            label: 'Фильтр',
            items: const [
              FilterDropdownItem(value: null, label: 'Нет', isReset: true),
              FilterDropdownItem(value: 'a', label: 'Опция A'),
            ],
            onChanged: (_) {},
          ),
        ),
      ));
      expect(find.text('Фильтр'), findsOneWidget);
    });

    testWidgets('отображает выбранное значение', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FilterDropdown<String>(
            value: 'a',
            label: 'Фильтр',
            items: const [
              FilterDropdownItem(value: null, label: 'Нет', isReset: true),
              FilterDropdownItem(value: 'a', label: 'Опция A'),
            ],
            onChanged: (_) {},
          ),
        ),
      ));
      expect(find.text('Опция A'), findsOneWidget);
    });

    testWidgets('выбор элемента вызывает onChanged', (tester) async {
      String? selected;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FilterDropdown<String>(
            value: null,
            label: 'Фильтр',
            items: const [
              FilterDropdownItem(value: null, label: 'Нет', isReset: true),
              FilterDropdownItem(value: 'a', label: 'Опция A'),
            ],
            onChanged: (v) => selected = v,
          ),
        ),
      ));

      await tester.tap(find.text('Фильтр'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Опция A'));
      await tester.pumpAndSettle();

      expect(selected, 'a');
    });
  });
}
