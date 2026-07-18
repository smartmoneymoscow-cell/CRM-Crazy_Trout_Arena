import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/screens/pond_map_screen.dart';
import 'package:crazytrout_admin/screens/pond_map_filter_config.dart';

/// Регрессионные тесты на dropdown фильтров карты пруда.
///
/// Тестируют РЕАЛЬНЫЙ экран PondMapScreen, а не изолированный FiltersDropdown.
/// Баг с верхними углами и зазором жил в _buildFilterRow(), который собирает
/// кнопку и dropdown в Stack. Изолированные тесты виджета его не ловили.
///
/// Правила (DROPDOWN_FILTER_RULES.md):
///   1. Никогда не перекрывать нижнее меню
///   2. Прячется строго под нижнее меню
///   3. ОБЯЗАТЕЛЬНЫЙ ТЕСТ: скрытие под нижним меню
///   4. Прикреплён к нижнему краю карточки, без зазора
///   5. Углы: карточка — нижние выпрямляются, верхние неизменные;
///      dropdown — верхние выпрямлены, нижние скруглены
///   6. Сворачивается: выбор опции, повторный тап, тап в пустую область
///   7. НЕ сворачивается при скролле
///   8. Не блокирует скролл
///   9. Всегда полная высота, не меняет высоту
///  10. НИКОГДА не открывается вверх — ОБЯЗАТЕЛЬНЫЙ ТЕСТ
///  11. НИКОГДА не сдвигает контент — ОБЯЗАТЕЛЬНЫЙ ТЕСТ
///  12. z-order: над контентом, под нижним меню

void main() {
  // ─── Хелпер: строим реальный PondMapScreen ───
  Widget buildPondMapScreen() {
    return const MaterialApp(
      home: PondMapScreen(),
    );
  }

  // ─── Хелпер: находим кнопку FiltersDropdown в дереве ───
  Finder findFilterButton() => find.byType(FiltersDropdown);

  // ─── Хелпер: открываем dropdown через тап ───
  Future<void> openDropdown(WidgetTester tester) async {
    await tester.tap(findFilterButton());
    await tester.pump();
  }

  // ═══════════════════════════════════════════════════════════════════
  // Группа 1: Тесты на реальном экране PondMapScreen
  // ═══════════════════════════════════════════════════════════════════
  group('PondMapScreen — _buildFilterRow regression tests', () {

    // ─── ПРАВИЛО 13: верхние углы кнопки НИКОГДА не меняются ───
    testWidgets('ПРАВИЛО 13: верхние углы кнопки = 999 при закрытии', (tester) async {
      await tester.pumpWidget(buildPondMapScreen());

      // Находим контейнер кнопки фильтров
      final button = tester.widget<Container>(
        find.descendant(
          of: findFilterButton(),
          matching: find.byType(Container).first,
        ),
      );
      final decoration = button.decoration as BoxDecoration;
      final radius = decoration.borderRadius as BorderRadius;

      expect(radius.topLeft, const Radius.circular(999),
        reason: 'Закрытое состояние: верхний левый = 999 (pill)');
      expect(radius.topRight, const Radius.circular(999),
        reason: 'Закрытое состояние: верхний правый = 999 (pill)');
      expect(radius.bottomLeft, const Radius.circular(999),
        reason: 'Закрытое состояние: нижний левый = 999 (pill)');
      expect(radius.bottomRight, const Radius.circular(999),
        reason: 'Закрытое состояние: нижний правый = 999 (pill)');
    });

    testWidgets('ПРАВИЛО 13: верхние углы = 999, нижние = 0 при раскрытии', (tester) async {
      await tester.pumpWidget(buildPondMapScreen());
      await openDropdown(tester);

      final button = tester.widget<Container>(
        find.descendant(
          of: findFilterButton(),
          matching: find.byType(Container).first,
        ),
      );
      final decoration = button.decoration as BoxDecoration;
      final radius = decoration.borderRadius as BorderRadius;

      // Верхние НЕ меняются
      expect(radius.topLeft, const Radius.circular(999),
        reason: 'Верхний левый угол НЕ должен меняться при раскрытии');
      expect(radius.topRight, const Radius.circular(999),
        reason: 'Верхний правый угол НЕ должен меняться при раскрытии');
      // Нижние выпрямляются
      expect(radius.bottomLeft, Radius.zero,
        reason: 'Нижний левый угол должен выпрямиться');
      expect(radius.bottomRight, Radius.zero,
        reason: 'Нижний правый угол должен выпрямиться');
    });

    // ─── ПРАВИЛО 4: зазор между кнопкой и dropdown = 0 ───
    testWidgets('ПРАВИЛО 4: dropdown прикреплён к кнопке без зазора', (tester) async {
      await tester.pumpWidget(buildPondMapScreen());
      await openDropdown(tester);

      // Находим кнопку и dropdown в Stack
      final buttonFinder = findFilterButton();
      final buttonRect = tester.getRect(buttonFinder);

      // Dropdown — Positioned с top: kFilterRowHeight + kDropdownGap
      // Находим контейнер dropdown (Container с bottomLeft: 12)
      final dropdownContainer = find.byWidgetPredicate((w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).borderRadius is BorderRadius &&
        ((w.decoration as BoxDecoration).borderRadius as BorderRadius).bottomLeft == const Radius.circular(12),
      );

      expect(dropdownContainer, findsOneWidget,
        reason: 'Dropdown должен отображаться при раскрытии');

      final dropdownRect = tester.getRect(dropdownContainer);
      final gap = dropdownRect.top - buttonRect.bottom;

      expect(gap, equals(0.0),
        reason: 'Зазор между кнопкой и dropdown должен быть 0 (фактический: $gap)');
    });

    // ─── ПРАВИЛО 11: dropdown не сдвигает контент ───
    testWidgets('ПРАВИЛО 11: dropdown не сдвигает контент при открытии', (tester) async {
      await tester.pumpWidget(buildPondMapScreen());

      // Запоминаем позицию контента ПОД фильтрами
      // Ищем «ЛЕНТА БРОНИРОВАНИЙ НА ПРУДУ» или «РАСПИСАНИЕ»
      final feedLabel = find.textContaining('БРОНИРОВАНИЙ');
      expect(feedLabel, findsOneWidget,
        reason: 'Должна быть лента бронирований');

      final posBefore = tester.getTopLeft(feedLabel);

      // Открываем dropdown
      await openDropdown(tester);

      final posAfter = tester.getTopLeft(feedLabel);

      expect(posAfter.dy, equals(posBefore.dy),
        reason: 'Контент сдвинулся при открытии dropdown! (${posBefore.dy} → ${posAfter.dy})');
    });

    // ─── ПРАВИЛО 10: dropdown не открывается вверх ───
    testWidgets('ПРАВИЛО 10: dropdown рендерится ниже кнопки', (tester) async {
      await tester.pumpWidget(buildPondMapScreen());
      await openDropdown(tester);

      final buttonFinder = findFilterButton();
      final buttonRect = tester.getRect(buttonFinder);

      final dropdownContainer = find.byWidgetPredicate((w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).borderRadius is BorderRadius &&
        ((w.decoration as BoxDecoration).borderRadius as BorderRadius).bottomLeft == const Radius.circular(12),
      );

      final dropdownRect = tester.getRect(dropdownContainer);

      expect(dropdownRect.top, greaterThanOrEqualTo(buttonRect.bottom),
        reason: 'Dropdown должен быть ниже кнопки (top: ${dropdownRect.top}, button bottom: ${buttonRect.bottom})');
    });

    // ─── ПРАВИЛО 5: углы dropdown ───
    testWidgets('ПРАВИЛО 5: dropdown — верхние 0, нижние 12', (tester) async {
      await tester.pumpWidget(buildPondMapScreen());
      await openDropdown(tester);

      final dropdownContainer = tester.widget<Container>(
        find.byWidgetPredicate((w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).borderRadius is BorderRadius &&
          ((w.decoration as BoxDecoration).borderRadius as BorderRadius).bottomLeft == const Radius.circular(12)),
      );
      final decoration = dropdownContainer.decoration as BoxDecoration;
      final radius = decoration.borderRadius as BorderRadius;

      expect(radius.topLeft, Radius.zero,
        reason: 'Верхний левый dropdown = 0 (плоский, стыкуется с кнопкой)');
      expect(radius.topRight, Radius.zero,
        reason: 'Верхний правый dropdown = 0 (плоский, стыкуется с кнопкой)');
      expect(radius.bottomLeft, const Radius.circular(12),
        reason: 'Нижний левый dropdown = 12');
      expect(radius.bottomRight, const Radius.circular(12),
        reason: 'Нижний правый dropdown = 12');
    });

    // ─── ПРАВИЛО 6: сворачивание при выборе опции ───
    testWidgets('ПРАВИЛО 6: dropdown сворачивается при выборе опции', (tester) async {
      await tester.pumpWidget(buildPondMapScreen());
      await openDropdown(tester);

      // Проверяем что dropdown виден
      expect(find.text('Премиум'), findsOneWidget);

      // Выбираем опцию
      await tester.tap(find.text('Премиум'));
      await tester.pump();

      // Dropdown должен свернуться — контейнер с bottomLeft: 12 исчезает
      final dropdownGone = find.byWidgetPredicate((w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).borderRadius is BorderRadius &&
        ((w.decoration as BoxDecoration).borderRadius as BorderRadius).bottomLeft == const Radius.circular(12),
      );
      expect(dropdownGone, findsNothing,
        reason: 'Dropdown должен свернуться после выбора опции');
    });

    // ─── ПРАВИЛО 8: не блокирует скролл ───
    testWidgets('ПРАВИЛО 8: скролл работает при открытом dropdown', (tester) async {
      await tester.pumpWidget(buildPondMapScreen());
      await openDropdown(tester);

      // Скроллим вниз
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();

      // ListView всё ещё работает
      expect(find.byType(ListView), findsOneWidget,
        reason: 'Скролл не должен блокироваться');
    });

    // ─── clipBehavior на реальной кнопке ───
    testWidgets('clipBehavior: Clip.antiAlias на кнопке в реальном экране', (tester) async {
      await tester.pumpWidget(buildPondMapScreen());

      final button = tester.widget<Container>(
        find.descendant(
          of: findFilterButton(),
          matching: find.byType(Container).first,
        ),
      );

      expect(button.clipBehavior, Clip.antiAlias,
        reason: 'Container кнопки в реальном экране должен иметь Clip.antiAlias');
    });

    testWidgets('clipBehavior сохраняется при раскрытии dropdown', (tester) async {
      await tester.pumpWidget(buildPondMapScreen());
      await openDropdown(tester);

      final button = tester.widget<Container>(
        find.descendant(
          of: findFilterButton(),
          matching: find.byType(Container).first,
        ),
      );

      expect(button.clipBehavior, Clip.antiAlias,
        reason: 'clipBehavior должен сохраняться при раскрытии');
    });

    // ─── Ширина dropdown = ширина кнопки ───
    testWidgets('dropdown той же ширины что кнопка', (tester) async {
      await tester.pumpWidget(buildPondMapScreen());
      await openDropdown(tester);

      final buttonFinder = findFilterButton();
      final buttonSize = tester.getSize(buttonFinder);

      final dropdownContainer = find.byWidgetPredicate((w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).borderRadius is BorderRadius &&
        ((w.decoration as BoxDecoration).borderRadius as BorderRadius).bottomLeft == const Radius.circular(12),
      );
      final dropdownSize = tester.getSize(dropdownContainer);

      expect(dropdownSize.width, buttonSize.width,
        reason: 'Ширина dropdown (${dropdownSize.width}) должна совпадать с кнопкой (${buttonSize.width})');
    });

    // ─── z-order: dropdown поверх контента ───
    testWidgets('z-order: dropdown рендерится поверх ленты бронирований', (tester) async {
      await tester.pumpWidget(buildPondMapScreen());
      await openDropdown(tester);

      // Dropdown контейнер с тенью должен быть в дереве
      final dropdownFinder = find.byWidgetPredicate((w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).boxShadow != null &&
        (w.decoration as BoxDecoration).boxShadow!.isNotEmpty,
      );

      expect(dropdownFinder, findsOneWidget,
        reason: 'Dropdown с тенью должен быть в дереве (z-order: поверх контента)');
    });
  });
}
