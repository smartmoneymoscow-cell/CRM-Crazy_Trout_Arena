// ============================================================================
// report_finance_order_test.dart — Тесты для БАГА 3.1 + KpiCards
//
// Проверяем:
// 1. RevenueDynamicsChart — ПОСЛЕДНИЙ (5-й) виджет в списке
// 2. RevenueDynamicsChart НЕ перекрывает FinanceDashboardCard
// 3. Все 5 KPI-карточек отображаются
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

void main() {
  group('БАГ 3.1 — Порядок и наложение графиков', () {
    testWidgets('RevenueDynamicsChart — последний (5-й) виджет',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _goToReports(tester);

      final dashboardBox = tester.getRect(find.byType(FinanceDashboardCard));
      final pieBox = tester.getRect(find.byType(FinancePieChart));
      final kpiBox = tester.getRect(find.byType(KpiCards));
      final paymentBox = tester.getRect(find.byType(PaymentTariffCard));
      final dynamicsBox = tester.getRect(find.byType(RevenueDynamicsChart));

      expect(dashboardBox.top, lessThan(pieBox.top));
      expect(pieBox.top, lessThan(kpiBox.top));
      expect(kpiBox.top, lessThan(paymentBox.top));
      expect(paymentBox.top, lessThan(dynamicsBox.top));
    });

    testWidgets('RevenueDynamicsChart НЕ перекрывает FinanceDashboardCard (телефон)',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _goToReports(tester);

      final d = tester.getRect(find.byType(FinanceDashboardCard));
      final r = tester.getRect(find.byType(RevenueDynamicsChart));
      expect(d.overlaps(r), isFalse);
    });

    testWidgets('Нет наложения на планшете (800×1280)',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_tabletSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _goToReports(tester);

      final d = tester.getRect(find.byType(FinanceDashboardCard));
      final r = tester.getRect(find.byType(RevenueDynamicsChart));
      expect(d.overlaps(r), isFalse);
    });

    testWidgets('Все 5 блоков отчёта присутствуют',
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

    testWidgets('RevenueDynamicsChart видим при скролле вниз',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _goToReports(tester);

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -2000));
      await tester.pumpAndSettle();

      final r = tester.getRect(find.byType(RevenueDynamicsChart));
      expect(r.top, greaterThanOrEqualTo(0));
    });

    testWidgets('Заголовок "Динамика показателей" на месте',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _goToReports(tester);

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(find.text('Динамика показателей'), findsOneWidget);
    });
  });

  group('KpiCards — все 5 карточек отображаются', () {
    testWidgets('Все 5 KPI-заголовков видны на странице',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _goToReports(tester);

      // Скроллим вниз чтобы все KPI были видимы
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -1500));
      await tester.pumpAndSettle();

      expect(find.text('Средний чек'), findsOneWidget,
          reason: 'KPI "Средний чек" отображается');
      expect(find.text('LT / LTV'), findsOneWidget,
          reason: 'KPI "LT / LTV" отображается');
      expect(find.text('Всего клиентов'), findsOneWidget,
          reason: 'KPI "Всего клиентов" отображается');
      expect(find.text('Средний улов на клиента'), findsOneWidget,
          reason: 'KPI "Средний улов на клиента" отображается');
      expect(find.text('Оценка сервиса'), findsOneWidget,
          reason: 'KPI "Оценка сервиса" отображается');
    });

    testWidgets('KPI-карточки имеют ненулевую высоту',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _goToReports(tester);

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -1500));
      await tester.pumpAndSettle();

      // Проверяем что хотя бы одна KPI-картока имеет высоту > 0
      final kpiFinder = find.byType(KpiCards);
      final kpiRect = tester.getRect(kpiFinder);
      expect(kpiRect.height, greaterThan(100),
          reason: 'KpiCards должен иметь высоту > 100px (все 5 карточек)');
    });
  });
}
