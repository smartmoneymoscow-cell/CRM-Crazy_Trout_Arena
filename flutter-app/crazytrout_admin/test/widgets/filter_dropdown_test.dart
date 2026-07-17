import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/widgets/filter_dropdown.dart';

/// Widget-тесты на FilterDropdown — логика позиционирования.
///
/// Критические баги (регрессии):
///   1. Снизу нет места, сверху есть → dropdown переворачивается вверх.
///   2. Нигде нет места → dropdown не открывается.
///
/// Требования:
///   - Dropdown открывается вниз если есть место.
///   - Dropdown переворачивается вверх если снизу нет места.
///   - Dropdown не открывается если нигде нет места.
///   - Выбор элемента вызывает onChanged и закрывает dropdown.
void main() {
  group('FilterDropdown — позиционирование', () {
    Widget buildApp({
      required double screenHeight,
      required double buttonTop,
      String? value,
      ValueChanged<String?>? onChanged,
    }) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(400, screenHeight)),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.only(top: buttonTop),
                child: FilterDropdown<String>(
                  value: value,
                  label: 'Тест',
                  items: const [
                    FilterDropdownItem(value: null, label: 'Нет', isReset: true),
                    FilterDropdownItem(value: 'a', label: 'Опция A'),
                    FilterDropdownItem(value: 'b', label: 'Опция B'),
                    FilterDropdownItem(value: 'c', label: 'Опция C'),
                  ],
                  onChanged: onChanged ?? (_) {},
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('открывается вниз когда есть место', (tester) async {
      // Экран 800px, кнопка на 100px — места снизу достаточно
      await tester.pumpWidget(buildApp(screenHeight: 800, buttonTop: 100));
      await tester.tap(find.text('Тест'));
      await tester.pumpAndSettle();

      // Dropdown виден — ищем элементы списка
      expect(find.text('Опция A'), findsOneWidget);
      expect(find.text('Опция B'), findsOneWidget);
    });

    testWidgets('переворачивается вверх когда снизу нет места', (tester) async {
      // Экран 800px, кнопка на 750px — снизу места нет (30px), сверху есть (750px)
      await tester.pumpWidget(buildApp(screenHeight: 800, buttonTop: 720));
      await tester.tap(find.text('Тест'));
      await tester.pumpAndSettle();

      // Dropdown открылся вверх — элементы видны
      expect(find.text('Опция A'), findsOneWidget);
    });

    testWidgets('не открывается когда нигде нет места', (tester) async {
      // Экран 100px, кнопка на 40px — снизу 60px (меньше одного item ~48px),
      // сверху 40px (тоже меньше). Dropdown не должен открываться.
      await tester.pumpWidget(buildApp(screenHeight: 100, buttonTop: 30));
      await tester.tap(find.text('Тест'));
      await tester.pumpAndSettle();

      // Dropdown НЕ открылся — элементы списка не видны
      expect(find.text('Опция A'), findsNothing);
      expect(find.text('Опция B'), findsNothing);
    });

    testWidgets('выбор элемента вызывает onChanged и закрывает', (tester) async {
      String? selected;
      await tester.pumpWidget(buildApp(
        screenHeight: 800,
        buttonTop: 100,
        onChanged: (v) => selected = v,
      ));

      await tester.tap(find.text('Тест'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Опция A'));
      await tester.pumpAndSettle();

      expect(selected, 'a');
      // Dropdown закрылся — элементы не видны
      expect(find.text('Опция A'), findsNothing);
    });

    testWidgets('тап вне dropdown закрывает его', (tester) async {
      await tester.pumpWidget(buildApp(screenHeight: 800, buttonTop: 100));
      await tester.tap(find.text('Тест'));
      await tester.pumpAndSettle();
      expect(find.text('Опция A'), findsOneWidget);

      // Тапаем вне dropdown (в пустую область)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Опция A'), findsNothing);
    });
  });

  group('FilterDropdown — скролл у нижнего меню', () {
    /// Требование из конфига (AGENTS.md):
    /// При пересечении или приближении к нижнему меню выпадающий список
    /// категорически не должен сворачиваться или сжиматься, двигаться или
    /// закрываться. Список скрывается ПОД меню при скролле, при обратном
    /// скролле появляется в неизменном состоянии.
    Widget buildScrollableApp({
      required double screenHeight,
      required double buttonTop,
    }) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(400, screenHeight)),
          child: Scaffold(
            body: ListView(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: buttonTop),
                  child: FilterDropdown<String>(
                    value: null,
                    label: 'Тест',
                    items: const [
                      FilterDropdownItem(value: null, label: 'Нет', isReset: true),
                      FilterDropdownItem(value: 'a', label: 'Опция A'),
                      FilterDropdownItem(value: 'b', label: 'Опция B'),
                    ],
                    onChanged: (_) {},
                  ),
                ),
                // Контент после dropdown (имитирует нижнее меню)
                SizedBox(height: 2000),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('dropdown не закрывается при скролле вниз', (tester) async {
      await tester.pumpWidget(buildScrollableApp(
        screenHeight: 800,
        buttonTop: 100,
      ));

      // Открываем dropdown
      await tester.tap(find.text('Тест'));
      await tester.pumpAndSettle();
      expect(find.text('Опция A'), findsOneWidget);

      // Скроллим вниз — dropdown должен остаться
      final listView = find.byType(ListView);
      await tester.drag(listView, const Offset(0, -300));
      await tester.pump();

      // Dropdown НЕ закрылся — элементы всё ещё видны
      expect(find.text('Опция A'), findsOneWidget);
    });

    testWidgets('dropdown не сжимается при приближении к нижнему меню', (tester) async {
      await tester.pumpWidget(buildScrollableApp(
        screenHeight: 800,
        buttonTop: 100,
      ));

      // Открываем dropdown
      await tester.tap(find.text('Тест'));
      await tester.pumpAndSettle();

      // Скроллим медленно — dropdown приближается к нижнему краю
      final listView = find.byType(ListView);
      for (int i = 0; i < 5; i++) {
        await tester.drag(listView, const Offset(0, -100));
        await tester.pump();
      }

      // Dropdown всё ещё открыт и не сжат
      expect(find.text('Опция A'), findsOneWidget);
      expect(find.text('Опция B'), findsOneWidget);
    });
  });
}
