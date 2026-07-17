/// Константы и логика фильтров карты пруда.
/// Вынесены из pond_map_screen.dart для unit-тестирования.
/// ─────────────────────────────────────────────────────────
/// ⚠️ НЕ ИЗМЕНЯТЬ без обновления тестов в test/screens/pond_map_filter_test.dart.
///
/// Требования к dropdown фильтров:
///
///   1. gap = 0 → dropdown вплотную к кнопке (без зазора)
///   2. OverlayEntry (НЕ inline Stack) → контент НЕ двигается
///   3. Dropdown прикреплён к низу кнопки (CompositedTransformFollower)
///   4. Dropdown скроллится вместе с кнопкой — как часть контента страницы
///   5. При скролле вниз dropdown УХОДИТ ПОД нижнее меню (как любой контент)
///   6. При обратном скролле dropdown ПОЯВЛЯЕТСЯ ИЗ-ПОД меню в неизменном виде
///   7. Нижнее меню ВСЕГДА поверх dropdown (z-order)
///   8. НЕ закрывается при нехватке места
///   9. НЕ сжимается при приближении к нижнему меню
///  10. НЕ скроллится внутрь (нет SingleChildScrollView)
///  11. Tap-to-close: выбор варианта или tap на пустое место
///
/// ┌─────────────────────────────────────────────────────────────────┐
/// │ ТАБЛИЦА КРИТИЧЕСКИХ БАГОВ (НЕ ПОВТОРЯТЬ)                       │
/// ├─────────────────────────────────────────────────────────────────┤
/// │ # │ Баг                          │ Почему критический           │
/// ├───┼──────────────────────────────┼──────────────────────────────┤
/// │ 1 │ Контент двигается вниз       │ inline Stack двигает контент │
/// │ 2 │ Dropdown сжимается           │ пункты нечитаемые            │
/// │ 3 │ Dropdown закрывается         │ теряется контекст фильтрации │
/// │ 4 │ Dropdown летает при скролле  │ визуальный глитч             │
/// │ 5 │ Залезает за нижнее меню      │ нарушает z-order             │
/// │ 6 │ Скроллится внутрь            │ два скролла одновременно     │
/// └─────────────────────────────────────────────────────────────────┘

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

/// Высота одного пункта меню дропдауна.
const double kDropdownItemHeight = 44.0;

/// Вертикальный padding внутри дропдауна.
const double kDropdownVPadding = 8.0;

/// Высота нижней навигации (BottomNavigationBar + SafeArea).
const double kBottomNavHeight = 60.0;

/// Высота строки фильтров (кнопка + padding).
const double kFilterRowHeight = 36.0;
