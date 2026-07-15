import 'package:flutter/material.dart';

/// Константы и логика фильтров карты пруда.
/// Вынесены из pond_map_screen.dart для unit-тестирования.
/// ─────────────────────────────────────────────────────────
/// ⚠️ НЕ ИЗМЕНЯТЬ без обновления тестов в test/screens/pond_map_filter_test.dart.
/// Эти значения решают конкретные баги:
///   - gap = 0 → дропдаун вплотную к кнопке (баг: зазор 4px)
///   - maxDropdownH ограничивает высоту → не перекрывает нижнее меню

enum FilterValue { none, all, premium, standard, basic }

const Map<FilterValue, String> filterOptions = {
  FilterValue.none: 'Нет',
  FilterValue.all: 'Все клиенты',
  FilterValue.premium: 'Премиум',
  FilterValue.standard: 'Стандарт',
  FilterValue.basic: 'Базовый',
};

const Map<FilterValue, String> filterButtonLabels = {
  FilterValue.none: 'Фильтры',
  FilterValue.all: 'Все',
  FilterValue.premium: 'Премиум',
  FilterValue.standard: 'Стандарт',
  FilterValue.basic: 'Базовый',
};

/// Зазор между кнопкой и дропдауном. Должен быть 0 (вплотную).
const double kDropdownGap = 0.0;

/// Нахлёст dropdown на кнопку (px). При открытии border кнопки убирается,
/// dropdown сдвигается вверх на 1px, чтобы полностью перекрыть контур
/// и не оставлять видимого зазора.
const double kDropdownOverlap = 1.0;

/// Высота одного пункта меню дропдауна.
const double kDropdownItemHeight = 44.0;

/// Вертикальный padding внутри дропдауна.
const double kDropdownVPadding = 8.0;

/// Высота нижней навигации (BottomNavigationBar + SafeArea).
const double kBottomNavHeight = 60.0;

/// Рассчитывает максимальную высоту дропдауна, чтобы не перекрывать нижнее меню.
/// [btnBottomY] — глобальная Y-координата нижнего края кнопки.
/// [screenH] — высота экрана.
/// [bottomPadding] — нижний safe area (MediaQuery.padding.bottom).
double calcMaxDropdownHeight({
  required double btnBottomY,
  required double screenH,
  required double bottomPadding,
}) {
  return screenH - btnBottomY - kBottomNavHeight - bottomPadding - 8;
}
