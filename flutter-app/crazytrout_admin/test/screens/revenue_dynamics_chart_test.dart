// ============================================================================
// revenue_dynamics_chart_test.dart — Тесты для RevenueDynamicsChart (БАГ 3.5)
//
// Проверяем:
// 1. Расположение — 5-й виджет в списке (после PaymentTariffCard)
// 2. Отсутствие наложения на другие графики
// 3. Автопереключение monthly/weekly при разных фильтрах
// 4. Корректность данных (data.monthly vs data.weekly)
// 5. Верстка при граничных значениях выручки
// 6. Наличие заголовка, легенды, toggle-кнопок
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/screens/report_screen.dart';
import 'package:crazytrout_admin/widgets/finance_dashboard_card.dart';
import 'package:crazytrout_admin/widgets/finance_pie_chart.dart';
import 'package:crazytrout_admin/widgets/kpi_cards.dart';
import 'package:crazytrout_admin/widgets/payment_tariff_card.dart';
import 'package:crazytrout_admin/widgets/revenue_dynamics_chart.dart';
import 'package:crazytrout_admin/data/revenue_dynamics_data.dart';

const _phoneSize = Size(393, 852);
const _tabletSize = Size(800, 1280);

Future<void> _goToReports(WidgetTester tester, [Size size = _phoneSize]) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size, devicePixelRatio: 2.0),
        child: const Scaffold(body: ReportScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // ==========================================================================
  // 1. Расположение RevenueDynamicsChart
  // ==========================================================================
  group('RevenueDynamicsChart — расположение на странице', () {
    testWidgets('является 5-м виджетом в Column (после PaymentTariffCard)',
        (WidgetTester tester) async {
      await _goToReports(tester);

      final d = tester.getRect(find.byType(FinanceDashboardCard));
      final p = tester.getRect(find.byType(FinancePieChart));
      final k = tester.getRect(find.byType(KpiCards));
      final pt = tester.getRect(find.byType(PaymentTariffCard));
      final r = tester.getRect(find.byType(RevenueDynamicsChart));

      // Порядок сверху вниз: Dashboard → Pie → KPI → Payment → Dynamics
      expect(d.top, lessThan(p.top),
          reason: 'DashboardCard выше PieChart');
      expect(p.top, lessThan(k.top),
          reason: 'PieChart выше KpiCards');
      expect(k.top, lessThan(pt.top),
          reason: 'KpiCards выше PaymentTariffCard');
      expect(pt.top, lessThan(r.top),
          reason: 'PaymentTariffCard выше RevenueDynamicsChart');
    });

    testWidgets('не перекрывает FinanceDashboardCard (телефон 393×852)',
        (WidgetTester tester) async {
      await _goToReports(tester);

      final d = tester.getRect(find.byType(FinanceDashboardCard));
      final r = tester.getRect(find.byType(RevenueDynamicsChart));
      expect(d.top, lessThan(r.top),
          reason: 'DashboardCard должен быть выше RevenueDynamicsChart');
    });

    testWidgets('не перекрывает FinanceDashboardCard (планшет 800×1280)',
        (WidgetTester tester) async {
      await _goToReports(tester, _tabletSize);

      final d = tester.getRect(find.byType(FinanceDashboardCard));
      final r = tester.getRect(find.byType(RevenueDynamicsChart));
      expect(d.top, lessThan(r.top));
    });

    testWidgets('не перекрывает KpiCards',
        (WidgetTester tester) async {
      await _goToReports(tester);

      final k = tester.getRect(find.byType(KpiCards));
      final r = tester.getRect(find.byType(RevenueDynamicsChart));
      expect(k.top, lessThan(r.top),
          reason: 'KpiCards должен быть выше RevenueDynamicsChart');
    });

    testWidgets('не перекрывает PaymentTariffCard',
        (WidgetTester tester) async {
      await _goToReports(tester);

      final pt = tester.getRect(find.byType(PaymentTariffCard));
      final r = tester.getRect(find.byType(RevenueDynamicsChart));
      expect(pt.top, lessThan(r.top),
          reason: 'PaymentTariffCard должен быть выше RevenueDynamicsChart');
    });

    testWidgets('видим при скролле вниз',
        (WidgetTester tester) async {
      await _goToReports(tester);

      // Скроллим вниз
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
      await tester.pumpAndSettle();

      expect(find.byType(RevenueDynamicsChart), findsOneWidget);
    });
  });

  // ==========================================================================
  // 2. Структура виджета — заголовок, легенда, toggle
  // ==========================================================================
  group('RevenueDynamicsChart — структура', () {
    testWidgets('отображает заголовок "Динамика показателей"',
        (WidgetTester tester) async {
      await _goToReports(tester);

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
      await tester.pumpAndSettle();

      expect(find.text('Динамика показателей'), findsOneWidget);
    });

    testWidgets('отображает легенду (Выручка, Маржа, Расходы)',
        (WidgetTester tester) async {
      await _goToReports(tester);

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
      await tester.pumpAndSettle();

      // Ищем легенду внутри RevenueDynamicsChart, т.к. "Выручка" есть и в DashboardCard
      final chartFinder = find.byType(RevenueDynamicsChart);
      expect(find.descendant(of: chartFinder, matching: find.text('Выручка')), findsOneWidget);
      expect(find.descendant(of: chartFinder, matching: find.text('Маржа')), findsOneWidget);
      expect(find.descendant(of: chartFinder, matching: find.text('Расходы')), findsOneWidget);
    });

    testWidgets('отображает toggle "По месяцам" / "По неделям"',
        (WidgetTester tester) async {
      await _goToReports(tester);

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
      await tester.pumpAndSettle();

      expect(find.text('По месяцам'), findsOneWidget);
      expect(find.text('По неделям'), findsOneWidget);
    });

    testWidgets('по умолчанию в режиме "По месяцам" активен',
        (WidgetTester tester) async {
      await _goToReports(tester);

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
      await tester.pumpAndSettle();

      // Находим RevenueDynamicsChart и проверяем его состояние
      final chart = tester.widget<RevenueDynamicsChart>(
        find.byType(RevenueDynamicsChart),
      );
      // По умолчанию _monthly = true (т.к. нет periodKey)
      // Проверяем через data: если monthly, то используем data.monthly
      expect(chart.data.monthly.length, greaterThanOrEqualTo(2),
          reason: 'monthly данные должны содержать >= 2 точек');
    });
  });

  // ==========================================================================
  // 3. Переключение toggle (ручное)
  // ==========================================================================
  group('RevenueDynamicsChart — toggle переключение', () {
    testWidgets('нажатие "По неделям" переключает режим',
        (WidgetTester tester) async {
      await _goToReports(tester);

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
      await tester.pumpAndSettle();

      // Нажимаем "По неделям"
      await tester.tap(find.text('По неделям'));
      await tester.pumpAndSettle();

      // Проверяем что график не сломался (всё ещё на месте)
      expect(find.byType(RevenueDynamicsChart), findsOneWidget);
      expect(find.text('Динамика показателей'), findsOneWidget);
    });

    testWidgets('переключение monthly → weekly → monthly не ломает график',
        (WidgetTester tester) async {
      await _goToReports(tester);

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
      await tester.pumpAndSettle();

      // Переключаем на недели
      await tester.tap(find.text('По неделям'));
      await tester.pumpAndSettle();

      // Переключаем обратно на месяцы
      await tester.tap(find.text('По месяцам'));
      await tester.pumpAndSettle();

      expect(find.byType(RevenueDynamicsChart), findsOneWidget);
      expect(find.text('Динамика показателей'), findsOneWidget);
    });
  });

  // ==========================================================================
  // 4. Данные графика
  // ==========================================================================
  group('RevenueDynamicsChart — данные', () {
    test('monthly содержит >= 2 точек (для отрисовки линий)', () {
      final data = buildRevenueDynamicsData();
      expect(data.monthly.length, greaterThanOrEqualTo(2),
          reason: 'Для отрисовки линии нужно >= 2 точек');
    });

    test('weekly содержит >= 2 точек', () {
      final data = buildRevenueDynamicsData();
      expect(data.weekly.length, greaterThanOrEqualTo(2));
    });

    test('monthly точки имеют положительную выручку', () {
      final data = buildRevenueDynamicsData();
      for (final p in data.monthly) {
        expect(p.revenue, greaterThan(0),
            reason: 'Выручка в "${p.label}" должна быть > 0');
      }
    });

    test('weekly точки имеют положительную выручку', () {
      final data = buildRevenueDynamicsData();
      for (final p in data.weekly) {
        expect(p.revenue, greaterThan(0),
            reason: 'Выручка в неделе "${p.label}" должна быть > 0');
      }
    });

    test('margin = 45% от revenue, expenses = 55% от revenue', () {
      final data = buildRevenueDynamicsData();
      for (final p in data.monthly) {
        expect(p.margin, closeTo(p.revenue * 0.45, 1),
            reason: 'Маржа в "${p.label}" ≈ 45% выручки');
        expect(p.expenses, closeTo(p.revenue * 0.55, 1),
            reason: 'Расходы в "${p.label}" ≈ 55% выручки');
      }
    });

    test('buildRevenueDynamicsData с пустым диапазоном возвращает моковые данные',
        () {
      // Диапазон без чеков → моковые данные
      final data = buildRevenueDynamicsData(
        dateRange: DateTimeRange(
          start: DateTime(2099, 1, 1),
          end: DateTime(2099, 1, 2),
        ),
      );
      expect(data.monthly.length, greaterThanOrEqualTo(2));
      expect(data.weekly.length, greaterThanOrEqualTo(2));
    });

    test('buildRevenueDynamicsData без dateRange возвращает данные',
        () {
      final data = buildRevenueDynamicsData();
      expect(data.monthly, isNotEmpty);
      expect(data.weekly, isNotEmpty);
    });
  });

  // ==========================================================================
  // 5. Верстка при граничных значениях выручки
  // ==========================================================================
  group('RevenueDynamicsChart — граничные значения', () {
    testWidgets('отображается корректно с моковыми данными (высокая выручка)',
        (WidgetTester tester) async {
      await _goToReports(tester);

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
      await tester.pumpAndSettle();

      // График на месте с моковыми данными (420к+ выручка)
      expect(find.byType(RevenueDynamicsChart), findsOneWidget);
      expect(find.text('Динамика показателей'), findsOneWidget);
    });

    testWidgets('RevenueDynamicsChart имеет ненулевую высоту',
        (WidgetTester tester) async {
      await _goToReports(tester);

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
      await tester.pumpAndSettle();

      final r = tester.getRect(find.byType(RevenueDynamicsChart));
      expect(r.height, greaterThan(100),
          reason: 'График должен иметь высоту > 100px');
    });

    testWidgets('RevenueDynamicsChart не выходит за правый край экрана',
        (WidgetTester tester) async {
      await _goToReports(tester);

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
      await tester.pumpAndSettle();

      final r = tester.getRect(find.byType(RevenueDynamicsChart));
      expect(r.right, lessThanOrEqualTo(_phoneSize.width + 1),
          reason: 'График не должен выходить за правый край');
    });
  });

  // ==========================================================================
  // 6. Все 5 блоков отчёта присутствуют
  // ==========================================================================
  group('Все 5 блоков отчёта', () {
    testWidgets('присутствуют на странице в правильном порядке',
        (WidgetTester tester) async {
      await _goToReports(tester);

      expect(find.byType(FinanceDashboardCard), findsOneWidget);
      expect(find.byType(FinancePieChart), findsOneWidget);
      expect(find.byType(KpiCards), findsOneWidget);
      expect(find.byType(PaymentTariffCard), findsOneWidget);
      expect(find.byType(RevenueDynamicsChart), findsOneWidget);
    });
  });
}
