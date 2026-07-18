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

    // ─── Требование 13: верхние углы НЕ меняются при раскрытии ───

    testWidgets('закрыт — все углы 12', (tester) async {
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

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      final radius = decoration.borderRadius as BorderRadius;

      expect(radius.topLeft, const Radius.circular(12));
      expect(radius.topRight, const Radius.circular(12));
      expect(radius.bottomLeft, const Radius.circular(12));
      expect(radius.bottomRight, const Radius.circular(12));
    });

    testWidgets('открыт — верхние углы 12, нижние 0', (tester) async {
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

      // Открываем dropdown
      await tester.tap(find.text('Фильтр'));
      await tester.pump();

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      final radius = decoration.borderRadius as BorderRadius;

      // Верхние углы НЕ меняются — всегда 12
      expect(radius.topLeft, const Radius.circular(12),
        reason: 'Верхний левый угол НЕ должен меняться при раскрытии');
      expect(radius.topRight, const Radius.circular(12),
        reason: 'Верхний правый угол НЕ должен меняться при раскрытии');
      // Нижние углы выпрямляются
      expect(radius.bottomLeft, Radius.zero,
        reason: 'Нижний левый угол должен выпрямиться');
      expect(radius.bottomRight, Radius.zero,
        reason: 'Нижний правый угол должен выпрямиться');
    });

    testWidgets('clipBehavior включён на кнопке', (tester) async {
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

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.clipBehavior, Clip.antiAlias,
        reason: 'Container кнопки должен клиппать содержимое по скруглению');
    });
  });
}
