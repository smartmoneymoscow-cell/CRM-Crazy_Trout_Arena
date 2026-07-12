import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/main.dart';

void main() {
  group('App — smoke tests', () {
    testWidgets('приложение запускается без крашей', (WidgetTester tester) async {
      await tester.pumpWidget(const CrazyTroutAdminApp());
      expect(find.text('Чек'), findsOneWidget);
    });

    testWidgets('нижнее меню содержит все 5 вкладок', (WidgetTester tester) async {
      await tester.pumpWidget(const CrazyTroutAdminApp());
      expect(find.text('Карта'), findsOneWidget);
      expect(find.text('Чек'), findsOneWidget);
      expect(find.text('Чеки'), findsOneWidget);
      expect(find.text('P&L'), findsOneWidget);
      expect(find.text('Профиль'), findsOneWidget);
    });

    testWidgets('экран чека содержит заголовок "Выставление чека"', (WidgetTester tester) async {
      await tester.pumpWidget(const CrazyTroutAdminApp());
      expect(find.text('Выставление чека'), findsOneWidget);
    });

    testWidgets('поиск клиента присутствует', (WidgetTester tester) async {
      await tester.pumpWidget(const CrazyTroutAdminApp());
      expect(find.text('Поиск по имени или телефону…'), findsOneWidget);
    });

    testWidgets('кнопка QR-сканера присутствует', (WidgetTester tester) async {
      await tester.pumpWidget(const CrazyTroutAdminApp());
      expect(find.byTooltip('Сканировать QR клиента'), findsOneWidget);
    });

    testWidgets('кнопка "Гость · без анкеты" присутствует', (WidgetTester tester) async {
      await tester.pumpWidget(const CrazyTroutAdminApp());
      expect(find.text('Гость · без анкеты'), findsOneWidget);
    });

    testWidgets('кнопка "Добавить рыбу" присутствует', (WidgetTester tester) async {
      await tester.pumpWidget(const CrazyTroutAdminApp());
      expect(find.text('+ Добавить рыбу'), findsOneWidget);
    });

    testWidgets('кнопка "Создать и распечатать чек" присутствует', (WidgetTester tester) async {
      await tester.pumpWidget(const CrazyTroutAdminApp());
      expect(find.text('Создать и распечатать чек'), findsOneWidget);
    });
  });
}
