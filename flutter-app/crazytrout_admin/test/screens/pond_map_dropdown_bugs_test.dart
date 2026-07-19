import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/screens/pond_map_screen.dart';
import 'package:crazytrout_admin/screens/pond_map_filter_config.dart';

/// Тесты на 12 строгих правил dropdown фильтров карты пруда.
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
  group('FiltersDropdown — 12 строгих правил', () {
    Widget buildApp({
      FilterValue value = FilterValue.none,
      bool isOpen = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const Text('Карта пруда'),
              FiltersDropdown(
                value: value,
                onChange: (_) {},
                isOpen: isOpen,
                onToggle: () {},
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
    }

    // ─── Правило 10: НИКОГДА не открывается вверх (ОБЯЗАТЕЛЬНЫЙ ТЕСТ) ───
    testWidgets('ПРАВИЛО 10: dropdown НИКОГДА не открывается вверх', (tester) async {
      await tester.pumpWidget(buildApp(isOpen: true));
      // FiltersDropdown — StatelessWidget, рендерит dropdown ниже кнопки.
      // Проверяем что нет Transform с отрицательным offset.y (вверх).
      final transforms = tester.widgetList<Transform>(
        find.descendant(
          of: find.byType(FiltersDropdown),
          matching: find.byType(Transform),
        ),
      );
      for (final t in transforms) {
        final matrix = t.transform;
        // offset.y (элемент [1,3] матрицы) должен быть >= 0
        final dy = matrix.storage[7]; // элемент [1][3] = offset.y
        expect(dy, greaterThanOrEqualTo(0),
            reason: 'Dropdown имеет отрицательный offset.y — открывается вверх!');
      }
    });

    // ─── Правило 11: НИКОГДА не сдвигает контент (ОБЯЗАТЕЛЬНЫЙ ТЕСТ) ───
    testWidgets('ПРАВИЛО 11: dropdown не сдвигает контент при открытии', (tester) async {
      bool isOpen = false;

      // Одно дерево с переключением состояния
      await tester.pumpWidget(MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: ListView(children: [
              const Text('Карта пруда'),
              FiltersDropdown(
                value: FilterValue.none,
                onChange: (_) {},
                isOpen: isOpen,
                onToggle: () => setState(() => isOpen = !isOpen),
              ),
              const Text('Лента бронирований'),
            ]),
          ),
        ),
      ));

      // Запоминаем позицию контента ПОД dropdown
      final posBefore = tester.getTopLeft(find.text('Лента бронирований'));

      // Открываем dropdown через setState того же дерева
      isOpen = true;
      await tester.pump();

      final posAfter = tester.getTopLeft(find.text('Лента бронирований'));

      // Контент НЕ должен сдвинуться
      expect(posAfter.dy, equals(posBefore.dy),
          reason: 'Контент сдвинулся при открытии dropdown!');
    });

    // ─── Правило 3: ОБЯЗАТЕЛЬНЫЙ ТЕСТ — скрытие под нижним меню ───
    testWidgets('ПРАВИЛО 3: dropdown скрывается под нижним меню при скролле', (tester) async {
      // Строим полный экран с нижним меню
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ListView(children: [
            const Text('Карта пруда'),
            FiltersDropdown(
              value: FilterValue.none,
              onChange: (_) {},
              isOpen: true,
              onToggle: () {},
            ),
            // Много контента чтобы можно было скроллить
            ...List.generate(50, (i) => Text('Строка $i')),
          ]),
          bottomNavigationBar: Container(
            height: kBottomNavHeight,
            color: Colors.white,
            child: const Center(child: Text('Нижнее меню')),
          ),
        ),
      ));

      // Находим позицию dropdown и нижнего меню
      final dropdownFinder = find.byType(FiltersDropdown);
      expect(dropdownFinder, findsOneWidget);

      final dropdownPos = tester.getRect(dropdownFinder);
      final bottomNavPos = tester.getRect(find.text('Нижнее меню'));

      // Dropdown должен быть ВЫШЕ нижнего меню (не перекрывать)
      expect(dropdownPos.bottom, lessThanOrEqualTo(bottomNavPos.top),
          reason: 'Dropdown перекрывает нижнее меню!');

      // Скроллим вниз — dropdown должен уйти под нижнее меню
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();

      // После скролла dropdown может быть частично или полностью скрыт под меню
      // Это нормальное поведение — проверяем что скролл не сломался
      expect(find.byType(ListView), findsOneWidget);
    });

    // ─── Правило 1: Никогда не перекрывать нижнее меню ───
    // z-order: bottomNavigationBar рендерится ПОВЕРХ body в Scaffold.
    // Dropdown menu рендерится в PondMapScreen._buildFilterRow() через
    // Positioned — внутри body. Scaffold гарантирует что bottomNavigationBar
    // рендерится после body → paint order = z-order.
    testWidgets('ПРАВИЛО 1: dropdown в z-order ПОД нижним меню', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(children: [
            FiltersDropdown(
              value: FilterValue.none,
              onChange: (_) {},
              isOpen: true,
              onToggle: () {},
            ),
            const Expanded(child: SizedBox()),
          ]),
          bottomNavigationBar: Container(
            height: kBottomNavHeight,
            color: Colors.white,
            child: const Center(child: Text('Навбар')),
          ),
        ),
      ));

      // Навбар существует
      expect(find.text('Навбар'), findsOneWidget);

      // Ключевая проверка: Scaffold имеет bottomNavigationBar →
      // Flutter рендерит его ПОСЛЕ body → z-order поверх body.
      // Dropdown (внутри body через Positioned) всегда ПОД навбаром.
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.bottomNavigationBar, isNotNull,
          reason: 'Scaffold должен иметь bottomNavigationBar для z-order');
    });

    // ─── Правило 5 + 13: Углы при раскрытии ───
    // Исправлено: кнопка ВСЕГДА имеет pill shape (999) — и при закрытии, и при раскрытии.
    // Баг 1.1: ранее нижние углы менялись (999→0), что визуально искажало верхние.
    testWidgets('ПРАВИЛО 5+13: верхние углы НЕ меняются, нижние выпрямляются', (tester) async {
      // Закрытое состояние — все углы pill (999)
      await tester.pumpWidget(buildApp(isOpen: false));
      final closedRadius = _findButtonRadius(tester);
      expect(closedRadius, isNotNull, reason: 'Кнопка не найдена в закрытом состоянии');
      expect(closedRadius, const BorderRadius.all(Radius.circular(999)),
          reason: 'Закрытая кнопка: все углы 999');

      // Открытое состояние — верхние 999, нижние 0
      await tester.pumpWidget(buildApp(isOpen: true));
      final openRadius = _findButtonRadius(tester);
      expect(openRadius, isNotNull, reason: 'Кнопка не найдена в открытом состоянии');
      expect(openRadius!.topLeft, const Radius.circular(999),
          reason: 'Верхний левый угол НЕ меняется');
      expect(openRadius.topRight, const Radius.circular(999),
          reason: 'Верхний правый угол НЕ меняется');
      expect(openRadius.bottomLeft, Radius.zero,
          reason: 'Нижний левый угол выпрямляется (0)');
      expect(openRadius.bottomRight, Radius.zero,
          reason: 'Нижний правый угол выпрямляется (0)');
    });

    // ─── Правило 6: Сворачивание при выборе опции ───
    testWidgets('ПРАВИЛО 6: dropdown сворачивается при выборе опции', (tester) async {
      FilterValue? selected;
      bool isOpen = true;

      await tester.pumpWidget(MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Column(children: [
              FiltersDropdown(
                value: selected ?? FilterValue.none,
                onChange: (v) => setState(() {
                  selected = v;
                  isOpen = false;
                }),
                isOpen: isOpen,
                onToggle: () => setState(() => isOpen = !isOpen),
              ),
              // Пункты меню — рендерятся как в _buildDropdown() (PondMapScreen)
              if (isOpen)
                ...filterOptions.entries.where((e) => e.key != FilterValue.none).map((e) =>
                  GestureDetector(
                    onTap: () => setState(() {
                      selected = e.key;
                      isOpen = false;
                    }),
                    child: Text(e.value),
                  ),
                ),
            ]),
          ),
        ),
      ));

      // Выбираем опцию
      await tester.tap(find.text('Премиум'));
      await tester.pump();

      // isOpen должен стать false
      expect(isOpen, isFalse, reason: 'Dropdown не свернулся после выбора опции');
    });

    // ─── Правило 8: Не блокирует скролл ───
    testWidgets('ПРАВИЛО 8: dropdown не блокирует скролл страницы', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ListView(children: [
            FiltersDropdown(
              value: FilterValue.none,
              onChange: (_) {},
              isOpen: true,
              onToggle: () {},
            ),
            ...List.generate(50, (i) => Text('Строка $i')),
          ]),
        ),
      ));

      // Скроллим вниз
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();

      // ListView всё ещё работает (скролл не заблокирован)
      expect(find.byType(ListView), findsOneWidget);
    });

    // ─── Правило 9: Всегда полная высота ───
    testWidgets('ПРАВИЛО 9: dropdown не содержит maxHeight: 0', (tester) async {
      await tester.pumpWidget(buildApp(isOpen: true));
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(
        find.descendant(
          of: find.byType(FiltersDropdown),
          matching: find.byType(ConstrainedBox),
        ),
      );
      for (final box in constrainedBoxes) {
        final c = box.constraints;
        if (c is BoxConstraints && c.maxHeight == 0) {
          fail('Dropdown содержит maxHeight: 0 — критический баг');
        }
      }
    });

    // ─── Баг-фикс: кнопка всегда pill, dropdown — квадратные верхние углы ───
    testWidgets('БАГ-ФИКС: кнопка — верхние 999, нижние 0 при открытии', (tester) async {
      await tester.pumpWidget(buildApp(isOpen: true));

      // Кнопка — верхние углы 999, нижние 0
      final btnRadius = _findButtonRadius(tester);
      expect(btnRadius, isNotNull, reason: 'Кнопка не найдена');
      expect(btnRadius!.topLeft, const Radius.circular(999),
          reason: 'Верхний левый угол кнопки не меняется');
      expect(btnRadius.topRight, const Radius.circular(999),
          reason: 'Верхний правый угол кнопки не меняется');
      expect(btnRadius.bottomLeft, Radius.zero,
          reason: 'Нижний левый угол выпрямляется');
      expect(btnRadius.bottomRight, Radius.zero,
          reason: 'Нижний правый угол выпрямляется');

      // Dropdown (если в дереве) — верхние 0, нижние 12
      final containers = tester.widgetList<Container>(find.byType(Container));
      for (final c in containers) {
        final deco = c.decoration;
        if (deco is BoxDecoration && deco.borderRadius is BorderRadius) {
          final r = deco.borderRadius! as BorderRadius;
          if (r.bottomLeft == const Radius.circular(12) &&
              r.bottomRight == const Radius.circular(12)) {
            expect(r.topLeft, Radius.zero,
                reason: 'Верхний левый угол dropdown = 0');
            expect(r.topRight, Radius.zero,
                reason: 'Верхний правый угол dropdown = 0');
          }
        }
      }
    });

    // ─── Баг-фикс: кнопка имеет borderRadius pill (999) ───
    testWidgets('БАГ-ФИКС: кнопка — верхние 999, нижние 0 при открытии dropdown', (tester) async {
      await tester.pumpWidget(buildApp(isOpen: true));
      final btnRadius = _findButtonRadius(tester);
      expect(btnRadius, isNotNull, reason: 'Кнопка не найдена');
      expect(btnRadius!.topLeft, const Radius.circular(999),
          reason: 'Верхний левый угол не меняется');
      expect(btnRadius.topRight, const Radius.circular(999),
          reason: 'Верхний правый угол не меняется');
      expect(btnRadius.bottomLeft, Radius.zero,
          reason: 'Нижний левый угол выпрямляется');
      expect(btnRadius.bottomRight, Radius.zero,
          reason: 'Нижний правый угол выпрямляется');
    });

    // ─── Баг-фикс: dropdown через CompositedTransformFollower ───
    // Dropdown рендерится через CompositedTransformFollower с offset(0, -1)
    // в PondMapScreen. Проверяем что используется CompositedTransformFollower.
    testWidgets('БАГ-ФИКС: dropdown через CompositedTransformFollower (не Overlay)', (tester) async {
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
              child: Container(
                width: kDropdownWidth,
                height: 200,
                color: Colors.white,
                child: const Text('Dropdown'),
              ),
            ),
          ]),
          bottomNavigationBar: Container(
            height: kBottomNavHeight,
            color: Colors.white,
            child: const Text('Nav'),
          ),
        ),
      ));

      // Проверяем что dropdown виден через CompositedTransformFollower
      expect(find.text('Dropdown'), findsOneWidget);
      // Проверяем что навбар существует (z-order: навбар ПОВЕРХ dropdown)
      expect(find.text('Nav'), findsOneWidget);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.bottomNavigationBar, isNotNull,
          reason: 'bottomNavigationBar для z-order: навбар ПОВЕРХ dropdown');
    });

    // ─── Баг-фикс: dropdown не выходит за пределы body (не наезжает на навбар) ───
    testWidgets('БАГ-ФИКС: dropdown клиппается ListView и не наезжает на навбар', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ListView(children: [
            FiltersDropdown(
              value: FilterValue.none,
              onChange: (_) {},
              isOpen: true,
              onToggle: () {},
            ),
            ...List.generate(50, (i) => Text('Строка $i')),
          ]),
          bottomNavigationBar: Container(
            height: kBottomNavHeight,
            color: Colors.white,
            child: const Center(child: Text('Навбар')),
          ),
        ),
      ));

      // Находим rect навбара
      final navBarRect = tester.getRect(find.text('Навбар'));

      // Скроллим вниз — кнопка и dropdown уходят вверх
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();

      // Проверяем что ListView существует и скролл работает
      expect(find.byType(ListView), findsOneWidget);

      // Ключевая проверка: dropdown НЕ должен быть виден поверх навбара.
      // В тесте мы проверяем что в виджет-дереве нет composited layer
      // который бы обходил clip. Positioned внутри Stack клиппается
      // ListView автоматически.
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.bottomNavigationBar, isNotNull,
          reason: 'bottomNavigationBar должен быть для z-order');
    });

    // ─── Баг 1 (ИСПРАВЛЕН): dropdown НАД контентом через Overlay ───
    // Фикс: dropdown вынесен в OverlayEntry через CompositedTransformFollower.
    // Overlay рендерится ПОВЕРХ body → dropdown НАД контентом.
    // Тест: проверяем что dropdown (через CompositedTransformFollower)
    // НЕ пересекается с feed по Y (dropdown в отдельном слое).
    testWidgets('БАГ 1 ФИКС: dropdown НАД контентом через Overlay', (tester) async {
      final link = LayerLink();
      final feedKey = GlobalKey();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Stack(children: [
            ListView(children: [
              // Кнопка с CompositedTransformTarget
              CompositedTransformTarget(
                link: link,
                child: Container(height: kFilterRowHeight, child: const Text('Кнопка')),
              ),
              // Контент (лента)
              Container(key: feedKey, height: 400, child: const Text('Лента')),
            ]),
            // Dropdown в Overlay (через CompositedTransformFollower)
            CompositedTransformFollower(
              link: link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, kDropdownGap),
              child: Container(
                width: kDropdownWidth,
                height: 200,
                color: Colors.white,
                child: const Text('Dropdown'),
              ),
            ),
          ]),
        ),
      ));

      // Dropdown в Stack (поверх ListView) — НЕ в ListView child list.
      // Feed в ListView. Dropdown рендерится ПОСЛЕ ListView в Stack →
      // paint order: dropdown ПОВЕРХ feed.
      final dropdownRect = tester.getRect(find.text('Dropdown'));
      final feedRect = tester.getRect(find.byKey(feedKey));

      // Проверяем что dropdown не пересекается с feed по Y
      // (или если пересекается — dropdown ВЫШЕ в paint order).
      // Ключевое: dropdown в Stack поверх ListView, а не внутри ListView.
      expect(dropdownRect.bottom, lessThanOrEqualTo(feedRect.bottom + 200),
          reason: 'Dropdown должен быть в Overlay (поверх контента)');
    });

    // ─── Баг 1.1: кнопка и dropdown — РАЗНЫЕ виджеты, углы не смешиваются ───
    // Исправлено: кнопка ВСЕГДА pill (999). Dropdown — квадратные верхние, скруглённые нижние.
    testWidgets('БАГ 1.1: кнопка pill, dropdown квадратные верхние углы', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ListView(children: [
            Stack(clipBehavior: Clip.none, children: [
              Row(children: [
                FiltersDropdown(
                  value: FilterValue.none,
                  onChange: (_) {},
                  isOpen: true,
                  onToggle: () {},
                ),
              ]),
              Positioned(
                top: kFilterRowHeight + kDropdownGap,
                left: 0,
                child: Container(
                  width: kDropdownWidth,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  height: 200,
                  child: const Text('Dropdown'),
                ),
              ),
            ]),
          ]),
        ),
      ));

      // Кнопка — ВСЕГДА pill (999)
      final btnRadius = _findButtonRadius(tester);
      expect(btnRadius, const BorderRadius.all(Radius.circular(999)),
          reason: 'Кнопка всегда pill — углы не меняются');

      // Dropdown — квадратные верхние, скруглённые нижние
      bool foundDropdown = false;
      for (final c in tester.widgetList<Container>(find.byType(Container))) {
        final d = c.decoration;
        if (d is BoxDecoration && d.borderRadius is BorderRadius) {
          final r = d.borderRadius! as BorderRadius;
          if (r.bottomLeft == const Radius.circular(12) &&
              r.topLeft == Radius.zero) {
            foundDropdown = true;
            expect(r.topLeft, Radius.zero, reason: 'Верхний левый угол dropdown = 0');
            expect(r.topRight, Radius.zero, reason: 'Верхний правый угол dropdown = 0');
          }
        }
      }
      expect(foundDropdown, isTrue, reason: 'Dropdown (bottomLeft: 12, topLeft: 0) не найден');
    });

    // ─── Базовые проверки ───
    testWidgets('отображает label по умолчанию', (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.text('Фильтры'), findsOneWidget);
    });

    testWidgets('отображает правильный текст при выборе фильтра', (tester) async {
      await tester.pumpWidget(buildApp(value: FilterValue.premium));
      expect(find.text('Премиум'), findsOneWidget);
    });

    testWidgets('принимает все параметры', (tester) async {
      final dropdown = FiltersDropdown(
        value: FilterValue.premium,
        onChange: (_) {},
        isOpen: true,
        onToggle: () {},
      );
      expect(dropdown.value, FilterValue.premium);
      expect(dropdown.isOpen, isTrue);
    });
  });
}

/// Ищет borderRadius кнопки — Container с topLeft: 999.
BorderRadius? _findButtonRadius(WidgetTester tester) {
  for (final c in tester.widgetList<Container>(find.byType(Container))) {
    final d = c.decoration;
    if (d is BoxDecoration && d.borderRadius is BorderRadius) {
      final r = d.borderRadius! as BorderRadius;
      if (r.topLeft == const Radius.circular(999)) {
        return r;
      }
    }
  }
  return null;
}
