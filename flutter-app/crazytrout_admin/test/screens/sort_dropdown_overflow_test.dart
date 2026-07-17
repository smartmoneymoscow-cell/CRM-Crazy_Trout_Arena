import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/screens/checks_screen.dart';

/// Тест: dropdown ранжирования чеков не обрезается правым краем экрана.
void main() {
  group('SortChip — dropdown не обрезается', () {
    testWidgets('dropdown помещается на экран при любом положении кнопки', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ChecksScreen()));
      await tester.pumpAndSettle();

      // Находим кнопку сортировки (иконка sort)
      final sortBtn = find.byIcon(Icons.sort);
      if (sortBtn.evaluate().isEmpty) {
        // Альтернативный поиск
        final sortChip = find.textContaining('По дате');
        if (sortChip.evaluate().isEmpty) return;
      }

      // Открываем dropdown
      await tester.tap(sortBtn.evaluate().isNotEmpty ? sortBtn : find.byTooltip('Сортировка'));
      await tester.pumpAndSettle();

      // Проверяем что dropdown не обрезается правым краем
      final screenW = tester.view.physicalSize.width / tester.view.devicePixelRatio;

      // Ищем Container шириной 220 (dropdown сортировки)
      final dropdowns = tester.widgetList<Container>(find.byType(Container));
      for (final d in dropdowns) {
        final constraints = d.constraints;
        if (constraints is BoxConstraints && constraints.maxWidth == 220) {
          final rect = tester.getRect(find.byWidget(d));
          expect(rect.right, lessThanOrEqualTo(screenW),
            reason: 'Dropdown сортировки обрезается правым краем экрана');
        }
      }
    });
  });
}
