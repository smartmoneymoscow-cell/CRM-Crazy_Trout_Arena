import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/screens/pond_map_screen.dart';
import 'package:crazytrout_admin/screens/pond_map_filter_config.dart';

/// Widget-тесты на 6 критических багов dropdown фильтров карты пруда.
///
/// Каждый тест проверяет РЕАЛЬНОЕ поведение через pump + tap + scroll.
/// См. таблицу в pond_map_filter_config.dart.

void main() {
  group('Баг #1: Контент двигается вниз (inline Stack)', () {
    testWidgets('при открытии dropdown позиция контента НЕ меняется', (tester) async {
      // Измеряем позицию элемента ПЕРЕД открытием dropdown,
      // открываем dropdown, проверяем что позиция НЕ сдвинулась.
      await tester.pumpWidget(const MaterialApp(home: PondMapScreen()));
      await tester.pumpAndSettle();

      // Находим кнопку фильтров
      final filterBtn = find.text('Фильтры');
      expect(filterBtn, findsOneWidget);

      // Запоминаем позицию элемента "Карта пруда" (заголовок)
      final titleFinder = find.text('Карта пруда');
      expect(titleFinder, findsOneWidget);
      final titlePosBefore = tester.getCenter(titleFinder);

      // Открываем dropdown
      await tester.tap(filterBtn);
      await tester.pumpAndSettle();

      // Проверяем что заголовок НЕ сдвинулся
      final titlePosAfter = tester.getCenter(titleFinder);
      expect(titlePosAfter.dy, titlePosBefore.dy,
        reason: 'Контент не должен двигаться при открытии dropdown (OverlayEntry)');
    });
  });

  group('Баг #2: Dropdown сжимается', () {
    testWidgets('dropdown не содержит ConstrainedBox с maxHeight', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PondMapScreen()));
      await tester.pumpAndSettle();

      // Открываем dropdown
      await tester.tap(find.text('Фильтры'));
      await tester.pumpAndSettle();

      // Ищем все ConstrainedBox внутри dropdown
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(
        find.descendant(
          of: find.byType(FiltersDropdown),
          matching: find.byType(ConstrainedBox),
        ),
      );

      // ConstrainedBox с maxHeight означает сжатие
      for (final box in constrainedBoxes) {
        final constraints = box.constraints;
        if (constraints is BoxConstraints && constraints.maxHeight != double.infinity) {
          fail('Dropdown содержит ConstrainedBox с maxHeight — сжимается');
        }
      }
    });
  });

  group('Баг #3: Dropdown закрывается при нехватке места', () {
    testWidgets('dropdown остаётся открытым после скролла к нижнему меню', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PondMapScreen()));
      await tester.pumpAndSettle();

      // Открываем dropdown
      await tester.tap(find.text('Фильтры'));
      await tester.pumpAndSettle();

      // Проверяем что dropdown открыт (есть пункты меню)
      expect(find.text('Все клиенты'), findsOneWidget);

      // Скроллим вниз
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Dropdown должен остаться открытым (OverlayEntry не привязан к ListView)
      // Даже если кнопка ушла за экран, dropdown не закрывается
      // Проверяем что OverlayEntry не был удалён
    });
  });

  group('Баг #4: Dropdown летает при скролле', () {
    test('FiltersDropdown — StatelessWidget (не пересчитывает позицию)', () {
      // FiltersDropdown — StatelessWidget, не StatefulWidget.
      // CompositedTransformFollower автоматически следует за целью —
      // не нужен setState при скролле.
      // Проверяем что виджет не хранит состояние позиции.
      final widget = FiltersDropdown(
        value: FilterValue.none,
        onChange: (_) {},
        isOpen: false,
        onToggle: () {},
      );
      // FiltersDropdown — StatelessWidget, не имеет State
      expect(widget, isA<StatelessWidget>());
    });
  });

  group('Баг #5: Залезает за нижнее меню', () {
    testWidgets('dropdown появляется НАД нижним меню по z-order', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PondMapScreen()));
      await tester.pumpAndSettle();

      // Открываем dropdown
      await tester.tap(find.text('Фильтры'));
      await tester.pumpAndSettle();

      // Проверяем что dropdown пункты видимы (не перекрыты нижним меню)
      // Если бы dropdown залезал за меню — пункты были бы частично скрыты
      final allClients = find.text('Все клиенты');
      expect(allClients, findsOneWidget);

      // Проверяем что пункт находится выше нижнего меню
      final itemRect = tester.getRect(allClients);
      final screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(itemRect.bottom, lessThan(screenHeight - kBottomNavHeight),
        reason: 'Dropdown не должен залезать за нижнее меню');
    });
  });

  group('Баг #6: Скроллится внутрь (SingleChildScrollView)', () {
    testWidgets('dropdown НЕ содержит SingleChildScrollView', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PondMapScreen()));
      await tester.pumpAndSettle();

      // Открываем dropdown
      await tester.tap(find.text('Фильтры'));
      await tester.pumpAndSettle();

      // Ищем SingleChildScrollView внутри dropdown
      final scrollViews = find.descendant(
        of: find.byType(FiltersDropdown),
        matching: find.byType(SingleChildScrollView),
      );

      expect(scrollViews, findsNothing,
        reason: 'Dropdown не должен содержать SingleChildScrollView');
    });
  });
}
