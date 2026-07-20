// ============================================================================
// report_finance_order_test.dart — Тесты: порядок графиков + KPI + фильтры
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/screens/report_screen.dart';
import 'package:crazytrout_admin/widgets/finance_dashboard_card.dart';
import 'package:crazytrout_admin/widgets/finance_pie_chart.dart';
import 'package:crazytrout_admin/widgets/kpi_cards.dart';
import 'package:crazytrout_admin/widgets/payment_tariff_card.dart';
import 'package:crazytrout_admin/widgets/revenue_dynamics_chart.dart';

const _phoneSize = Size(393, 852);
const _tabletSize = Size(800, 1280);

Future<void> _goToReports(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ReportScreen())));
  await tester.pumpAndSettle();
}

/// Открывает dropdown фильтра и выбирает пункт [label]
Future<void> _selectFilter(WidgetTester tester, String label) async {
  // Находим контейнер с текстом "Период" или текущим значением фильтра
  final filterText = find.text('Период');
  expect(filterText, findsWidgets, reason: 'Текст "Период" не найден');
  // Тапаем по GestureDetector над текстом
  final gesture = find.ancestor(
    of: filterText,
    matching: find.byType(GestureDetector),
  );
  await tester.tap(gesture.first);
  await tester.pumpAndSettle();

  // Тапаем по нужному пункту в overlay
  final option = find.text(label).last;
  await tester.tap(option);
  await tester.pumpAndSettle();
}

void main() {
  const skipFinance = true; // TODO: remove after v1.5.18 release
  group('БАГ 3.1 — Порядок и наложение графиков', () {
    testWidgets('RevenueDynamicsChart — последний (5-й) виджет',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _goToReports(tester);

      final d = tester.getRect(find.byType(FinanceDashboardCard));
      final pie = tester.getRect(find.byType(FinancePieChart));
      final kpi = tester.getRect(find.byType(KpiCards));
      final pay = tester.getRect(find.byType(PaymentTariffCard));
      final dyn = tester.getRect(find.byType(RevenueDynamicsChart));

      expect(d.top, lessThan(pie.top));
      expect(pie.top, lessThan(kpi.top));
      expect(kpi.top, lessThan(pay.top));
      expect(pay.top, lessThan(dyn.top));
    });

    testWidgets('Нет наложения Dashboard ↔ Dynamics (телефон)',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _goToReports(tester);
      // Проверяем порядок: Dashboard выше Dynamics
      final d = tester.getRect(find.byType(FinanceDashboardCard));
      final r = tester.getRect(find.byType(RevenueDynamicsChart));
      expect(d.top, lessThan(r.top),
          reason: 'Dashboard должен быть выше Dynamics');
    });

    testWidgets('Нет наложения на планшете',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_tabletSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _goToReports(tester);
      final d = tester.getRect(find.byType(FinanceDashboardCard));
      final r = tester.getRect(find.byType(RevenueDynamicsChart));
      expect(d.top, lessThan(r.top),
          reason: 'Dashboard должен быть выше Dynamics на планшете');
    });

    testWidgets('Все 5 блоков присутствуют',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _goToReports(tester);
      expect(find.byType(FinanceDashboardCard), findsOneWidget);
      expect(find.byType(FinancePieChart), findsOneWidget);
      expect(find.byType(KpiCards), findsOneWidget);
      expect(find.byType(PaymentTariffCard), findsOneWidget);
      expect(find.byType(RevenueDynamicsChart), findsOneWidget);
    });

    testWidgets('DynamicsChart видим после скролла',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _goToReports(tester);
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(RevenueDynamicsChart)).top, greaterThanOrEqualTo(0));
    });
  }, skip: skipFinance);

  group('KpiCards — все 5 карточек', () {
    testWidgets('Все 5 KPI-заголовков видны',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _goToReports(tester);
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -1500));
      await tester.pumpAndSettle();

      expect(find.text('Средний чек'), findsOneWidget);
      expect(find.text('LT / LTV'), findsOneWidget);
      expect(find.text('Клиенты'), findsOneWidget);
      expect(find.text('Ср. улов'), findsOneWidget);
      expect(find.text('Оценка сервиса'), findsOneWidget);
    });

    testWidgets('KpiCards высота > 100px (все карточки)',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _goToReports(tester);
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -1500));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(KpiCards)).height, greaterThan(100));
    });
  }, skip: skipFinance);

  group('Фильтры — наложение при разных периодах', () {
    testWidgets('Нет наложения при фильтре "Сегодня"',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _goToReports(tester);
      await _selectFilter(tester, 'Сегодня');

      final d = tester.getRect(find.byType(FinanceDashboardCard));
      final r = tester.getRect(find.byType(RevenueDynamicsChart));
      expect(d.top, lessThan(r.top), reason: 'С "Сегодня" Dashboard выше Dynamics');
    });

    testWidgets('Нет наложения при фильтре "Неделя"',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _goToReports(tester);
      await _selectFilter(tester, 'Неделя');

      final d = tester.getRect(find.byType(FinanceDashboardCard));
      final r = tester.getRect(find.byType(RevenueDynamicsChart));
      expect(d.top, lessThan(r.top), reason: 'С "Неделя" Dashboard выше Dynamics');
    });

    testWidgets('Нет наложения при фильтре "Месяц"',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _goToReports(tester);
      await _selectFilter(tester, 'Месяц');

      final d = tester.getRect(find.byType(FinanceDashboardCard));
      final r = tester.getRect(find.byType(RevenueDynamicsChart));
      expect(d.top, lessThan(r.top), reason: 'С "Месяц" Dashboard выше Dynamics');
    });

    testWidgets('Нет наложения при фильтре "Квартал"',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _goToReports(tester);
      await _selectFilter(tester, 'Квартал');

      final d = tester.getRect(find.byType(FinanceDashboardCard));
      final r = tester.getRect(find.byType(RevenueDynamicsChart));
      expect(d.top, lessThan(r.top), reason: 'С "Квартал" Dashboard выше Dynamics');
    });

    testWidgets('Нет наложения при фильтре "Все вр."',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _goToReports(tester);
      await _selectFilter(tester, 'Все вр.');

      final d = tester.getRect(find.byType(FinanceDashboardCard));
      final r = tester.getRect(find.byType(RevenueDynamicsChart));
      expect(d.top, lessThan(r.top), reason: 'С "Все вр." Dashboard выше Dynamics');
    });
  }, skip: skipFinance);
}
