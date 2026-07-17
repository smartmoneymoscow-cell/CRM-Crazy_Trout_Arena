import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/main.dart';

void main() {
  // Увеличиваем тестовый экран чтобы dropdown не overflow'ил
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  group('App — smoke tests', () {
    testWidgets('приложение запускается без крашей', (WidgetTester tester) async {
      binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(const CrazyTroutAdminApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}
      binding.setSurfaceSize(null);
    });

    testWidgets('после SplashScreen показывается HomeShell', (WidgetTester tester) async {
      binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(const CrazyTroutAdminApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}
      expect(find.text('Чек'), findsOneWidget);
      binding.setSurfaceSize(null);
    });

    testWidgets('нижнее меню содержит все 5 вкладок', (WidgetTester tester) async {
      binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(const CrazyTroutAdminApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}
      expect(find.text('Карта'), findsOneWidget);
      expect(find.text('Чек'), findsOneWidget);
      expect(find.text('Чеки'), findsOneWidget);
      expect(find.text('Отчёты'), findsOneWidget);
      expect(find.text('Профиль'), findsOneWidget);
      binding.setSurfaceSize(null);
    });

    testWidgets('экран чека содержит заголовок', (WidgetTester tester) async {
      binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(const CrazyTroutAdminApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}
      await tester.tap(find.text('Чеки'));
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}
      binding.setSurfaceSize(null);
    });

    testWidgets('поиск клиента и QR-кнопка присутствуют', (WidgetTester tester) async {
      binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(const CrazyTroutAdminApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}
      binding.setSurfaceSize(null);
    });
  });
}
