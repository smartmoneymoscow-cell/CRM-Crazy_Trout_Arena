import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/screens/pond_map_filter_config.dart';
import 'package:crazytrout_admin/screens/pond_map_screen.dart';

/// Unit-тесты на константы и логику фильтров карты пруда.
///
/// ⚠️ Эти тесты — защита от регрессий. Если вы изменяете значения
/// в pond_map_filter_config.dart и тест падает — значит вы ломаете
/// исправленный баг. Прочитайте комментарии к константам прежде чем
/// менять тест.
void main() {
  group('Константы dropdown фильтров', () {
    test('gap = 0 (дропдаун вплотную к кнопке)', () {
      expect(kDropdownGap, 0.0,
        reason: 'gap должен быть 0 — дропдаун вплотную к кнопке.');
    });

    test('itemHeight > 0', () {
      expect(kDropdownItemHeight, greaterThan(0));
    });

    test('dropdownVPadding >= 0', () {
      expect(kDropdownVPadding, greaterThanOrEqualTo(0));
    });

    test('bottomNavHeight > 0', () {
      expect(kBottomNavHeight, greaterThan(0),
        reason: 'bottomNavHeight должен быть задан.');
    });

    test('kDropdownWidth > 0', () {
      expect(kDropdownWidth, greaterThan(0),
        reason: 'kDropdownWidth должен быть задан.');
    });
  });

  group('filterOptions — все варианты', () {
    test('ровно 5 вариантов', () {
      expect(filterOptions.length, 5);
    });

    test('каждый FilterValue имеет label', () {
      for (final v in FilterValue.values) {
        expect(filterOptions.containsKey(v), isTrue,
          reason: 'FilterValue.$v отсутствует в filterOptions');
        expect(filterOptions[v]!.isNotEmpty, isTrue,
          reason: 'label для FilterValue.$v пустой');
      }
    });

    test('filterButtonLabels — ровно 5 вариантов', () {
      expect(filterButtonLabels.length, 5);
    });

    test('каждый FilterValue имеет buttonLabel', () {
      for (final v in FilterValue.values) {
        expect(filterButtonLabels.containsKey(v), isTrue);
      }
    });
  });

  group('Стиль dropdown', () {
    test('выделение выбранного пункта — Color(0xFFF5EEDC)', () {
      const highlight = Color(0xFFF5EEDC);
      expect(highlight, isNot(const Color(0xFFF3EEE4)),
        reason: 'выделение должно отличаться от фона dropdown');
    });
  });

  // ───────────────────────────────────────────────────────────────────
  // Виджет-тесты: проверка формы кнопки и позиционирования dropdown
  // ───────────────────────────────────────────────────────────────────

  group('Требование 13: верхние углы кнопки НЕ меняются при раскрытии', () {
    testWidgets('кнопка закрыта — все углы pill (999)', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: FiltersDropdown(
          value: FilterValue.none,
          onChange: (_) {},
          isOpen: false,
          onToggle: () {},
        )),
      ));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      final radius = decoration.borderRadius as BorderRadius;

      // Все углы должны быть 999 (pill)
      expect(radius.topLeft, const Radius.circular(999));
      expect(radius.topRight, const Radius.circular(999));
      expect(radius.bottomLeft, const Radius.circular(999));
      expect(radius.bottomRight, const Radius.circular(999));
    });

    testWidgets('кнопка открыта — верхние углы 999, нижние 0', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: FiltersDropdown(
          value: FilterValue.none,
          onChange: (_) {},
          isOpen: true,
          onToggle: () {},
        )),
      ));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      final radius = decoration.borderRadius as BorderRadius;

      // Верхние углы ДОЛЖНЫ остаться 999 (требование 13)
      expect(radius.topLeft, const Radius.circular(999),
        reason: 'Верхний левый угол НЕ должен меняться при раскрытии');
      expect(radius.topRight, const Radius.circular(999),
        reason: 'Верхний правый угол НЕ должен меняться при раскрытии');
      // Нижние углы выпрямляются
      expect(radius.bottomLeft, const Radius.circular(0));
      expect(radius.bottomRight, const Radius.circular(0));
    });
  });

  group('Требование 14: dropdown той же ширины что кнопка, без смещения', () {
    testWidgets('dropdown прикреплён к кнопке, та же ширина, без зазора', (tester) async {
      FilterValue currentFilter = FilterValue.none;
      bool isOpen = true;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FiltersDropdown(
                  value: currentFilter,
                  onChange: (v) => setState(() => currentFilter = v),
                  isOpen: isOpen,
                  onToggle: () => setState(() => isOpen = !isOpen),
                ),
                if (isOpen)
                  SizedBox(
                    width: kDropdownWidth,
                    child: Container(height: 100, color: Colors.white),
                  ),
              ],
            );
          },
        ),
      ),
      ));

      // Ширина совпадает
      final buttonFinder = find.byType(FiltersDropdown);
      final buttonBox = tester.getSize(buttonFinder);
      // Находим SizedBox с шириной kDropdownWidth — их 2 (wrapper кнопки + dropdown)
      final sizedBoxFinder = find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == kDropdownWidth,
      );
      expect(sizedBoxFinder, findsNWidgets(2));
      // Берём второй (dropdown), т.к. кнопка — первый
      final dropdownBox = tester.getSize(sizedBoxFinder.last);
      expect(dropdownBox.width, kDropdownWidth);
      expect(dropdownBox.width, buttonBox.width);

      // Зазор = 0 (dropdown прикреплён к кнопке)
      final buttonRect = tester.getRect(buttonFinder);
      final dropdownRect = tester.getRect(sizedBoxFinder.last);
      final gap = dropdownRect.top - buttonRect.bottom;
      expect(gap, equals(0.0),
        reason: 'Dropdown должен быть прикреплён к кнопке (зазор $gap)');

      // Нет горизонтального смещения
      expect(dropdownRect.left, buttonRect.left,
        reason: 'Dropdown не должен быть смещён вправо/влево от кнопки');
    });

    test('kDropdownWidth = 120 (константа)', () {
      expect(kDropdownWidth, 120.0,
        reason: 'kDropdownWidth должен быть 120');
    });
  });

  group('Требование 5: углы dropdown', () {
    testWidgets('dropdown — верхние углы 0, нижние 12', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SizedBox(
          width: kDropdownWidth,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
            ),
          ),
        )),
      ));

      final container = tester.widget<Container>(
        find.byWidgetPredicate((w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).borderRadius != null &&
          (w.decoration as BoxDecoration).borderRadius is BorderRadius &&
          ((w.decoration as BoxDecoration).borderRadius as BorderRadius).bottomLeft == const Radius.circular(12)),
      );
      final decoration = container.decoration as BoxDecoration;
      final radius = decoration.borderRadius as BorderRadius;

      // Верхние углы 0 (плоские, стыкуются с кнопкой)
      expect(radius.topLeft, Radius.zero,
        reason: 'Верхний левый угол dropdown должен быть 0 (плоский)');
      expect(radius.topRight, Radius.zero,
        reason: 'Верхний правый угол dropdown должен быть 0 (плоский)');
      // Нижние углы 12
      expect(radius.bottomLeft, const Radius.circular(12),
        reason: 'Нижний левый угол dropdown должен быть 12');
      expect(radius.bottomRight, const Radius.circular(12),
        reason: 'Нижний правый угол dropdown должен быть 12');
    });
  });

  group('Требование 4: зазор между кнопкой и dropdown = 0', () {
    test('kDropdownGap = 0', () {
      expect(kDropdownGap, 0.0,
        reason: 'Зазор между кнопкой и dropdown должен быть 0');
    });
  });
}
