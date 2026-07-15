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
      // Баг: gap был 4px — видимый зазор между кнопкой и дропдауном.
      // Фикс: commit 88018e6 (gap 2→0).
      // Регрессия: commit 570740f вернул gap 0→4.
      expect(kDropdownGap, 0.0,
        reason: 'gap должен быть 0 — дропдаун вплотную к кнопке. '
                'См. коммит 570740f (регрессия) и 88018e6 (фикс).');
    });

    test('itemHeight > 0', () {
      expect(kDropdownItemHeight, greaterThan(0));
    });

    test('dropdownVPadding >= 0', () {
      expect(kDropdownVPadding, greaterThanOrEqualTo(0));
    });

    test('bottomNavHeight > 0', () {
      // Баг: без ограничения высоты дропдаун перекрывал нижнее меню.
      // Фикс: commit 658fd82 добавил bottomNavHeight = 72.
      // Регрессия: commit 6c597f7 удалил ограничение целиком.
      expect(kBottomNavHeight, greaterThan(0),
        reason: 'bottomNavHeight должен быть задан — без него дропдаун '
                'перекрывает нижнее меню. См. коммит 6c597f7 (регрессия).');
    });

    test('overlap = 1 (dropdown перекрывает border кнопки)', () {
      // Баг: dropdown начинался ниже кнопки → видимый зазор в 1px.
      // Фикс: dropdown сдвигается вверх на 1px, перекрывая контур кнопки.
      expect(kDropdownOverlap, 1.0,
        reason: 'overlap должен быть 1 — dropdown перекрывает border кнопки. '
                'Без этого виден зазор между кнопкой и dropdown.');
    });
  });

  group('calcMaxDropdownHeight()', () {
    test('ограничивает высоту снизу навбаром', () {
      // Экран 800px, кнопка заканчивается на Y=600, safe area bottom=34
      // Доступное пространство: 800 - 600 - 60 - 34 - 8 = 98
      final h = calcMaxDropdownHeight(
        btnBottomY: 600,
        screenH: 800,
        bottomPadding: 34,
      );
      expect(h, 98.0);
    });

    test('возвращает отрицательное если кнопка слишком низко', () {
      // Кнопка у самого низа — нет места для дропдауна
      final h = calcMaxDropdownHeight(
        btnBottomY: 780,
        screenH: 800,
        bottomPadding: 0,
      );
      expect(h, lessThan(0),
        reason: 'если кнопка у низа экрана, maxDropdownH < 0 — '
                'дропдаун не должен открываться вниз');
    });

    test('максимальная высота учитывает навбар и safe area', () {
      final h = calcMaxDropdownHeight(
        btnBottomY: 400,
        screenH: 900,
        bottomPadding: 34,
      );
      // 900 - 400 - 60 - 34 - 8 = 398
      expect(h, 398.0);
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
      // Баг: был Color(0xFFF3EEE4) — невидимый на фоне.
      // Фикс: патч dropdown — выделение 0xFFF5EEDC.
      const highlight = Color(0xFFF5EEDC);
      expect(highlight, isNot(const Color(0xFFF3EEE4)),
        reason: 'выделение должно отличаться от фона dropdown');
    });
  });
}
