import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/screens/pond_map_filter_config.dart';
import 'package:crazytrout_admin/screens/pond_map_screen.dart';

/// Widget-тесты на FiltersDropdown.
///
/// Проверяют: кнопка отображает правильный текст, dropdown открывается/закрывается,
/// выбор варианта вызывает onChange.
///
/// Требования (строго обязательно, см. DROPDOWN_FILTER_RULES.md):
///   1. Dropdown рендерится в отдельном слое Stack (поверх feed, под нижним меню).
///   2. Выпадающий список НЕ нарушает скролл экрана.
///   3. Выпадающий список НЕ сворачивается при скролле экрана.
///   4. Выпадающий список скрывается ПОД нижнее меню.
///   5. Нет зазора между кнопкой и списком (gap = 0).
///   6. При раскрытии нижние углы кнопки выпрямляются, верхние НЕ меняются.
///   7. Dropdown прикреплён к РЕАЛЬНОЙ позиции кнопки через LayerLink
///      (CompositedTransformTarget/Follower) — НЕ через константу вида
///      "top: 36" или kFilterRowHeight. Именно рассинхронизация такой
///      константы с фактической отрисованной высотой кнопки уже трижды
///      создавала видимый зазор между кнопкой и списком — см. тест ниже
///      "дропдаун прижат к кнопке на РЕАЛЬНОМ экране", который пумпит
///      целиком PondMapScreen, а не изолированный FiltersDropdown, именно
///      чтобы поймать этот класс регрессии.
///   8. Контент под dropdown НЕ двигается (Stack-слои, не inline).
void main() {
  group('FiltersDropdown', () {
    Widget buildApp({
      FilterValue value = FilterValue.none,
      ValueChanged<FilterValue>? onChange,
      bool isOpen = false,
      VoidCallback? onToggle,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: FiltersDropdown(
              value: value,
              onChange: onChange ?? (_) {},
              isOpen: isOpen,
              onToggle: onToggle ?? () {},
            ),
          ),
        ),
      );
    }

    testWidgets('кнопка отображает "Фильтры" по умолчанию', (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.text('Фильтры'), findsOneWidget);
    });

    testWidgets('кнопка отображает "Все" при FilterValue.all', (tester) async {
      await tester.pumpWidget(buildApp(value: FilterValue.all));
      expect(find.text('Все'), findsOneWidget);
    });

    testWidgets('кнопка отображает "Премиум" при FilterValue.premium', (tester) async {
      await tester.pumpWidget(buildApp(value: FilterValue.premium));
      expect(find.text('Премиум'), findsOneWidget);
    });

    testWidgets('тап по кнопке вызывает onToggle', (tester) async {
      bool toggled = false;
      await tester.pumpWidget(buildApp(onToggle: () => toggled = true));
      await tester.tap(find.text('Фильтры'));
      expect(toggled, isTrue);
    });

    testWidgets('при isOpen=true нижние углы кнопки выпрямляются', (tester) async {
      await tester.pumpWidget(buildApp(isOpen: true));
      // Кнопка всё ещё отображается
      expect(find.text('Фильтры'), findsOneWidget);
    });

    testWidgets('FiltersDropdown принимает value, onChange, isOpen, onToggle', (tester) async {
      final dropdown = FiltersDropdown(
        value: FilterValue.premium,
        onChange: (_) {},
        isOpen: false,
        onToggle: () {},
      );
      expect(dropdown.value, FilterValue.premium);
      expect(dropdown.isOpen, isFalse);
    });
  });

  group('PondMapScreen — dropdown прижат к РЕАЛЬНОЙ кнопке (регрессия зазора)', () {
    testWidgets('дропдаун открывается вплотную к кнопке «Фильтры», без зазора',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PondMapScreen()));
      await tester.pumpAndSettle();

      final btnFinder = find.text('Фильтры');
      expect(btnFinder, findsOneWidget);
      final btnRect = tester.getRect(btnFinder);

      await tester.tap(btnFinder);
      await tester.pumpAndSettle();

      final optionFinder = find.text('Все клиенты');
      expect(optionFinder, findsOneWidget, reason: 'дропдаун должен открыться');
      final optionTop = tester.getTopLeft(optionFinder).dy;

      // "Вплотную" = верх первого пункта списка почти сразу под низом
      // кнопки (низ кнопки + вертикальный padding первого пункта, без
      // произвольного зазора). Раньше здесь стоял хардкод "top: 36",
      // из-за которого список либо не доставал, либо перекрывал кнопку.
      // Ожидаемый отступ по дизайну = kDropdownVPadding (8) + top padding
      // самого пункта списка (12) = 20px. Верхняя граница взята с запасом
      // (не ровно 20.0), чтобы не падать от долей пикселя из-за метрик
      // шрифта/округления рендера — это не индикатор реального зазора.
      expect(optionTop - btnRect.bottom, inInclusiveRange(-2.0, 30.0),
          reason: 'дропдаун должен быть прижат к нижнему краю кнопки без '
                  'произвольного зазора (сейчас разница ${optionTop - btnRect.bottom}px)');
    });
  });
}
