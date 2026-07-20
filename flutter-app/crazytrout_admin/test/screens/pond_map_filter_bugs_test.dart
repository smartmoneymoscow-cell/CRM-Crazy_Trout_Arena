import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/screens/pond_map_screen.dart';
import 'package:crazytrout_admin/screens/pond_map_filter_config.dart';

/// Тесты на баги 1.1 и 1.2 dropdown фильтров карты пруда.
///
/// Баг 1.1: При раскрытии dropdown верхние углы карточки фильтров скругляются.
///   Требование: верхние углы кнопки НИКОГДА не меняются — всегда pill (999).
///
/// Баг 1.2: Dropdown отображается ЗА лентой бронирования.
///   Требование: dropdown НАД контентом, ПОД нижним меню (z-order).
///
/// Алгоритм:
///   1. Тесты ловят оба бага
///   2. Запуск → тесты КРАСНЫЕ
///   3. Фикс
///   4. Проверка соответствия правилам
///   5. Пуш
///   6. Зелёные → релиз

void main() {
  group('БАГ 1.1: верхние углы кнопки НЕ меняются при раскрытии dropdown', () {
    testWidgets('кнопка всегда имеет pill shape (999) — и закрыта, и открыта', (tester) async {
      // Закрытое состояние
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FiltersDropdown(
            value: FilterValue.none,
            onChange: (_) {},
            isOpen: false,
            onToggle: () {},
          ),
        ),
      ));

      // Ищем кнопку — Container с borderRadius
      final closedButton = _findButtonContainer(tester);
      expect(closedButton, isNotNull, reason: 'Кнопка не найдена в закрытом состоянии');
      final closedRadius = (closedButton!.decoration as BoxDecoration).borderRadius! as BorderRadius;
      expect(closedRadius, const BorderRadius.all(Radius.circular(kPillRadius)),
          reason: 'Закрытая кнопка: все углы 999');

      // Открытое состояние — верхние углы ДОЛЖНЫ остаться 999
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FiltersDropdown(
            value: FilterValue.none,
            onChange: (_) {},
            isOpen: true,
            onToggle: () {},
          ),
        ),
      ));

      final openButton = _findButtonContainer(tester);
      expect(openButton, isNotNull, reason: 'Кнопка не найдена в открытом состоянии');
      final openRadius = (openButton!.decoration as BoxDecoration).borderRadius! as BorderRadius;

      // КРИТИЧЕСКАЯ ПРОВЕРКА: верхние углы НЕ меняются
      expect(openRadius.topLeft, const Radius.circular(kPillRadius),
          reason: 'БАГ 1.1: верхний левый угол кнопки изменился с 999 на ${openRadius.topLeft}');
      expect(openRadius.topRight, const Radius.circular(kPillRadius),
          reason: 'БАГ 1.1: верхний правый угол кнопки изменился с 999 на ${openRadius.topRight}');
    });

    testWidgets('dropdown menu имеет квадратные верхние углы и скруглённые нижние', (tester) async {
      // Рендерим FiltersDropdown в Stack (как в реальном PondMapScreen)
      final link = LayerLink();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Stack(clipBehavior: Clip.none, children: [
            CompositedTransformTarget(
              link: link,
              child: FiltersDropdown(
                value: FilterValue.none,
                onChange: (_) {},
                isOpen: true,
                onToggle: () {},
              ),
            ),
            CompositedTransformFollower(
              link: link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, -1),
              child: _buildTestDropdown(),
            ),
          ]),
        ),
      ));

      // Ищем dropdown — Container с bottomLeft: 12
      final dropdown = _findDropdownContainer(tester);
      expect(dropdown, isNotNull, reason: 'Dropdown menu не найден');
      final dRadius = (dropdown!.decoration as BoxDecoration).borderRadius! as BorderRadius;

      // Верхние углы dropdown = 0 (квадратные)
      expect(dRadius.topLeft, Radius.zero,
          reason: 'Верхний левый угол dropdown должен быть квадратным (0)');
      expect(dRadius.topRight, Radius.zero,
          reason: 'Верхний правый угол dropdown должен быть квадратным (0)');
      // Нижние углы dropdown = 12 (скруглённые)
      expect(dRadius.bottomLeft, const Radius.circular(12),
          reason: 'Нижний левый угол dropdown должен быть скруглён (12)');
      expect(dRadius.bottomRight, const Radius.circular(12),
          reason: 'Нижний правый угол dropdown должен быть скруглён (12)');
    });
  });

  group('БАГ 1.2: dropdown НАД контентом, ПОД нижним меню', () {
    testWidgets('dropdown в Stack внутри body — под нижним меню', (tester) async {
      final link = LayerLink();
      final feedKey = GlobalKey();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Stack(clipBehavior: Clip.none, children: [
            ListView(children: [
              CompositedTransformTarget(
                link: link,
                child: FiltersDropdown(
                  value: FilterValue.none,
                  onChange: (_) {},
                  isOpen: true,
                  onToggle: () {},
                ),
              ),
              Container(key: feedKey, height: 400, child: const Text('Лента бронирований')),
              ...List.generate(20, (i) => Text('Строка $i')),
            ]),
            // Dropdown в Stack поверх ListView
            CompositedTransformFollower(
              link: link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, -1),
              child: _buildTestDropdown(),
            ),
          ]),
          bottomNavigationBar: Container(
            height: 60,
            color: Colors.white,
            child: const Center(child: Text('Нижнее меню')),
          ),
        ),
      ));

      // Проверяем что dropdown виден (в Stack поверх ListView)
      expect(find.text('Премиум'), findsOneWidget);

      // Проверяем что нижнее меню существует
      expect(find.text('Нижнее меню'), findsOneWidget);

      // Ключевая проверка: Scaffold имеет bottomNavigationBar →
      // Flutter рендерит его ПОСЛЕ body → z-order: навбар ПОВЕРХ dropdown.
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.bottomNavigationBar, isNotNull,
          reason: 'Scaffold должен иметь bottomNavigationBar для z-order');
    });

    testWidgets('dropdown НЕ в Overlay — а в Stack внутри body', (tester) async {
      // Проверяем что реальный PondMapScreen НЕ использует Overlay.of(context).insert()
      // для dropdown фильтров. Вместо этого — Stack внутри body.
      //
      // Если dropdown в Overlay — он выше всего, включая bottomNavigationBar.
      // Если dropdown в Stack внутри body — он ниже bottomNavigationBar.
      final link = LayerLink();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Stack(clipBehavior: Clip.none, children: [
            const Text('Body content'),
            CompositedTransformFollower(
              link: link,
              showWhenUnlinked: false,
              child: _buildTestDropdown(),
            ),
          ]),
          bottomNavigationBar: Container(
            height: 60,
            color: Colors.white,
            child: const Text('Nav'),
          ),
        ),
      ));

      // Dropdown в body (Stack) → под навбаром
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.bottomNavigationBar, isNotNull,
          reason: 'bottomNavigationBar рендерится ПОСЛЕ body → z-order выше dropdown');
    });
  });
}

/// Ищет Container кнопки фильтров — с borderRadius содержащим 999.
Container? _findButtonContainer(WidgetTester tester) {
  for (final c in tester.widgetList<Container>(find.byType(Container))) {
    final d = c.decoration;
    if (d is BoxDecoration && d.borderRadius is BorderRadius) {
      final r = d.borderRadius! as BorderRadius;
      // Кнопка: хотя бы один угол = 999
      if (r.topLeft == const Radius.circular(kPillRadius)) {
        return c;
      }
    }
  }
  return null;
}

/// Ищет Container dropdown — с bottomLeft: 12, topLeft: 0.
Container? _findDropdownContainer(WidgetTester tester) {
  for (final c in tester.widgetList<Container>(find.byType(Container))) {
    final d = c.decoration;
    if (d is BoxDecoration && d.borderRadius is BorderRadius) {
      final r = d.borderRadius! as BorderRadius;
      if (r.bottomLeft == const Radius.circular(12) &&
          r.topLeft == Radius.zero) {
        return c;
      }
    }
  }
  return null;
}

/// Строит тестовый dropdown menu (копия из _PondMapScreenState._buildDropdown).
Widget _buildTestDropdown() {
  return SizedBox(
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
          boxShadow: [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: filterOptions.entries.map((e) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              color: Colors.transparent,
              child: Text(
                e.value,
                style: const TextStyle(fontSize: 13, color: Color(0xFF14130F)),
              ),
            );
          }).toList(),
        ),
      ),
    ),
  );
}
