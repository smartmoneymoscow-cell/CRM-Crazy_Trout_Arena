// ============================================================================
// pond_map_screen_tap_test.dart — Smoke-тесты на PondMapScreen.
//
// Проверяем что экран рендерится без крашей и ключевые элементы видны.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/screens/pond_map_screen.dart';
import 'package:crazytrout_admin/screens/pond_map_filter_config.dart';

void main() {
  group('PondMapScreen — smoke', () {
    testWidgets('экран рендерится без ошибок', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PondMapScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Карта пруда'), findsOneWidget);
    });

    testWidgets('отображает чип даты', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PondMapScreen()));
      await tester.pumpAndSettle();
      expect(find.text('12 июл'), findsOneWidget);
    });

    testWidgets('отображает чип времени', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PondMapScreen()));
      await tester.pumpAndSettle();
      expect(find.text('06:00'), findsOneWidget);
    });

    testWidgets('отображает кнопку фильтров', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PondMapScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Фильтры'), findsOneWidget);
    });

    testWidgets('отображает карту пруда', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PondMapScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(PondMapView), findsOneWidget);
    });

    testWidgets('отображает статистику загрузки', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PondMapScreen()));
      await tester.pumpAndSettle();
      expect(find.text('ЗАГРУЗКА'), findsOneWidget);
      expect(find.text('БРОНЕЙ'), findsOneWidget);
    });

    testWidgets('отображает ленту бронирований', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PondMapScreen()));
      await tester.pumpAndSettle();
      expect(find.textContaining('ЛЕНТА БРОНИРОВАНИЙ'), findsOneWidget);
    });
  });
}
