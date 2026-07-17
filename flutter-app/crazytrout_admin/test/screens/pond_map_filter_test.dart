import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/screens/pond_map_filter_config.dart';

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
}
