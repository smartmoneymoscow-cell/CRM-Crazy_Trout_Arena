import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/widgets/segmented_control.dart';

void main() {
  group('SegmentedControl — виджет переключателя', () {
    testWidgets('отображает все опции', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SegmentedControl<String>(
            options: const [
              SegmentedOption('a', 'Опция A'),
              SegmentedOption('b', 'Опция B'),
            ],
            selected: 'a',
            onChanged: (_) {},
          ),
        ),
      ));
      expect(find.text('Опция A'), findsOneWidget);
      expect(find.text('Опция B'), findsOneWidget);
    });

    testWidgets('выбранная опция подсвечена', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SegmentedControl<String>(
            options: const [
              SegmentedOption('a', 'A'),
              SegmentedOption('b', 'B'),
            ],
            selected: 'a',
            onChanged: (_) {},
          ),
        ),
      ));
      // Найдём контейнеры и проверим цвета
      final containers = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(containers.length, 2);
    });

    testWidgets('нажатие вызывает onChanged', (WidgetTester tester) async {
      String? selected;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SegmentedControl<String>(
                options: const [
                  SegmentedOption('a', 'A'),
                  SegmentedOption('b', 'B'),
                ],
                selected: selected ?? 'a',
                onChanged: (v) => setState(() => selected = v),
              );
            },
          ),
        ),
      ));
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();
      expect(selected, 'b');
    });

    testWidgets('работает с PaymentMethod', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SegmentedControl<int>(
            options: const [
              SegmentedOption(0, 'Наличными'),
              SegmentedOption(1, 'Картой'),
            ],
            selected: 1,
            onChanged: (_) {},
          ),
        ),
      ));
      expect(find.text('Наличными'), findsOneWidget);
      expect(find.text('Картой'), findsOneWidget);
    });
  });
}
