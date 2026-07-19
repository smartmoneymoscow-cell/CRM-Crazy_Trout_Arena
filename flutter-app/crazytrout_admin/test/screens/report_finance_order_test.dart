// ============================================================================
// report_finance_order_test.dart — Тесты для БАГА 3.1:
// RevenueDynamicsChart накладывается поверх FinanceDashboardCard.
//
// Проверяем:
// 1. RevenueDynamicsChart — ПОСЛЕДНИЙ (5-й) виджет в списке
// 2. RevenueDynamicsChart НЕ перекрывает FinanceDashboardCard
// 3. Порядок виджетов: Dashboard → Pie → KPI → Payment → Dynamics
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

/// Helper: создаёт ReportScreen в MaterialApp
Future<void> _goToReports(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ReportScreen())));
  await tester.pumpAndSettle();
}

void main() {
  group('БАГ 3.1 — Порядок и наложение графиков в Отчётах', () {
    // ──────────────────────────────────────────────────────────────────────
    // Тест 1: RevenueDynamicsChart — последний виджет в Column
    // ──────────────────────────────────────────────────────────────────────
    testWidgets('RevenueDynamicsChart расположен ПОСЛЕДНИМ (5-м) в списке виджетов',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _goToReports(tester);

      // Находим все ключевые виджеты
      final dashboardFinder = find.byType(FinanceDashboardCard);
      final pieFinder = find.byType(FinancePieChart);
      final kpiFinder = find.byType(KpiCards);
      final paymentFinder = find.byType(PaymentTariffCard);
      final dynamicsFinder = find.byType(RevenueDynamicsChart);

      expect(dashboardFinder, findsOneWidget, reason: 'FinanceDashboardCard не найден');
      expect(pieFinder, findsOneWidget, reason: 'FinancePieChart не найден');
      expect(kpiFinder, findsOneWidget, reason: 'KpiCards не найдены');
      expect(paymentFinder, findsOneWidget, reason: 'PaymentTariffCard не найден');
      expect(dynamicsFinder, findsOneWidget, reason: 'RevenueDynamicsChart не найден');

      // Проверяем порядок: вертикальная позиция каждого виджета
      final dashboardBox = tester.getRect(dashboardFinder);
      final pieBox = tester.getRect(pieFinder);
      final kpiBox = tester.getRect(kpiFinder);
      final paymentBox = tester.getRect(paymentFinder);
      final dynamicsBox = tester.getRect(dynamicsFinder);

      // Dashboard — первый (самый верхний)
      expect(dashboardBox.top, lessThan(pieBox.top),
          reason: 'FinanceDashboardCard должен быть ПЕРЕД FinancePieChart');
      expect(pieBox.top, lessThan(kpiBox.top),
          reason: 'FinancePieChart должен быть ПЕРЕД KpiCards');
      expect(kpiBox.top, lessThan(paymentBox.top),
          reason: 'KpiCards должен быть ПЕРЕД PaymentTariffCard');
      expect(paymentBox.top, lessThan(dynamicsBox.top),
          reason: 'PaymentTariffCard должен быть ПЕРЕД RevenueDynamicsChart');

      // RevenueDynamicsChart — ПОСЛЕДНИЙ
      expect(dynamicsBox.top, greaterThan(paymentBox.top),
          reason: 'RevenueDynamicsChart должен быть ПОСЛЕ PaymentTariffCard (5-й)');
    });

    // ──────────────────────────────────────────────────────────────────────
    // Тест 2: НЕТ наложения RevenueDynamicsChart на FinanceDashboardCard
    // ──────────────────────────────────────────────────────────────────────
    testWidgets('RevenueDynamicsChart НЕ перекрывает FinanceDashboardCard',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _goToReports(tester);

      final dashboardRect = tester.getRect(find.byType(FinanceDashboardCard));
      final dynamicsRect = tester.getRect(find.byType(RevenueDynamicsChart));

      // Наложение = пересечение прямоугольников
      final overlaps = dashboardRect.overlaps(dynamicsRect);

      expect(overlaps, isFalse,
          reason: 'RevenueDynamicsChart НЕ должен перекрывать FinanceDashboardCard. '
              'Dashboard: ${dashboardRect}, Dynamics: ${dynamicsRect}');
    });

    // ──────────────────────────────────────────────────────────────────────
    // Тест 3: Наложение на ПЛАНШЕТЕ
    // ──────────────────────────────────────────────────────────────────────
    testWidgets('Нет наложения на планшете (800×1280)',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_tabletSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _goToReports(tester);

      final dashboardRect = tester.getRect(find.byType(FinanceDashboardCard));
      final dynamicsRect = tester.getRect(find.byType(RevenueDynamicsChart));

      expect(dashboardRect.overlaps(dynamicsRect), isFalse,
          reason: 'На планшете RevenueDynamicsChart не должен перекрывать FinanceDashboardCard');
    });

    // ──────────────────────────────────────────────────────────────────────
    // Тест 4: RevenueDynamicsChart видим на экране (не обрезан)
    // ──────────────────────────────────────────────────────────────────────
    testWidgets('RevenueDynamicsChart видим при скролле вниз',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _goToReports(tester);

      // RevenueDynamicsChart может быть за пределами экрана — скроллим вниз
      final dynamicsFinder = find.byType(RevenueDynamicsChart);
      expect(dynamicsFinder, findsOneWidget);

      // Скроллим вниз, чтобы RevenueDynamicsChart стал видимым
      final scrollView = find.byType(SingleChildScrollView);
      await tester.drag(scrollView, const Offset(0, -2000));
      await tester.pumpAndSettle();

      // Теперь RevenueDynamicsChart должен быть видим
      final dynamicsRect = tester.getRect(dynamicsFinder);
      expect(dynamicsRect.top, greaterThanOrEqualTo(0),
          reason: 'RevenueDynamicsChart должен быть видим после скролла');
    });

    // ──────────────────────────────────────────────────────────────────────
    // Тест 5: Проверка порядка с фильтром "Сегодня"
    // ──────────────────────────────────────────────────────────────────────
    testWidgets('Порядок корректен с фильтром "Сегодня"',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _goToReports(tester);

      // Ищем FilterDropdown по иконке календаря или по типу
      final periodFinder = find.text('Период');
      expect(periodFinder, findsWidgets);

      // Нажимаем на dropdown "Период"
      final dropdown = find.ancestor(
        of: find.text('Период'),
        matching: find.byType(GestureDetector),
      ).first;
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Выбираем "Сегодня"
      if (find.text('Сегодня').evaluate().isNotEmpty) {
        await tester.tap(find.text('Сегодня').last);
        await tester.pumpAndSettle();
      }

      final dashboardRect = tester.getRect(find.byType(FinanceDashboardCard));
      final dynamicsRect = tester.getRect(find.byType(RevenueDynamicsChart));

      expect(dashboardRect.overlaps(dynamicsRect), isFalse,
          reason: 'С фильтром "Сегодня" нет наложения');
      expect(dynamicsRect.top, greaterThan(dashboardRect.bottom),
          reason: 'DynamicsChart должен быть ниже DashboardCard');
    });

    // ──────────────────────────────────────────────────────────────────────
    // Тест 6: Проверка порядка с фильтром "За месяц"
    // ──────────────────────────────────────────────────────────────────────
    testWidgets('Порядок корректен с фильтром "За месяц"',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _goToReports(tester);

      final dropdown = find.ancestor(
        of: find.text('Период'),
        matching: find.byType(GestureDetector),
      ).first;
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      if (find.text('За месяц').evaluate().isNotEmpty) {
        await tester.tap(find.text('За месяц').last);
        await tester.pumpAndSettle();
      }

      final dashboardRect = tester.getRect(find.byType(FinanceDashboardCard));
      final dynamicsRect = tester.getRect(find.byType(RevenueDynamicsChart));

      expect(dashboardRect.overlaps(dynamicsRect), isFalse,
          reason: 'С фильтром "За месяц" нет наложения');
    });

    // ──────────────────────────────────────────────────────────────────────
    // Тест 7: Проверка порядка с фильтром "За квартал"
    // ──────────────────────────────────────────────────────────────────────
    testWidgets('Порядок корректен с фильтром "За квартал"',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _goToReports(tester);

      final dropdown = find.ancestor(
        of: find.text('Период'),
        matching: find.byType(GestureDetector),
      ).first;
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      if (find.text('За квартал').evaluate().isNotEmpty) {
        await tester.tap(find.text('За квартал').last);
        await tester.pumpAndSettle();
      }

      final dashboardRect = tester.getRect(find.byType(FinanceDashboardCard));
      final dynamicsRect = tester.getRect(find.byType(RevenueDynamicsChart));

      expect(dashboardRect.overlaps(dynamicsRect), isFalse,
          reason: 'С фильтром "За квартал" нет наложения');
    });

    // ──────────────────────────────────────────────────────────────────────
    // Тест 8: Проверка порядка с фильтром "За неделю"
    // ──────────────────────────────────────────────────────────────────────
    testWidgets('Порядок корректен с фильтром "За неделю"',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _goToReports(tester);

      final dropdown = find.ancestor(
        of: find.text('Период'),
        matching: find.byType(GestureDetector),
      ).first;
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      if (find.text('За неделю').evaluate().isNotEmpty) {
        await tester.tap(find.text('За неделю').last);
        await tester.pumpAndSettle();
      }

      final dashboardRect = tester.getRect(find.byType(FinanceDashboardCard));
      final dynamicsRect = tester.getRect(find.byType(RevenueDynamicsChart));

      expect(dashboardRect.overlaps(dynamicsRect), isFalse,
          reason: 'С фильтром "За неделю" нет наложения');
    });

    // ──────────────────────────────────────────────────────────────────────
    // Тест 9: Проверка порядка с фильтром "За все время"
    // ──────────────────────────────────────────────────────────────────────
    testWidgets('Порядок корректен с фильтром "За все время"',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _goToReports(tester);

      final dropdown = find.ancestor(
        of: find.text('Период'),
        matching: find.byType(GestureDetector),
      ).first;
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      if (find.text('За все время').evaluate().isNotEmpty) {
        await tester.tap(find.text('За все время').last);
        await tester.pumpAndSettle();
      }

      final dashboardRect = tester.getRect(find.byType(FinanceDashboardCard));
      final dynamicsRect = tester.getRect(find.byType(RevenueDynamicsChart));

      expect(dashboardRect.overlaps(dynamicsRect), isFalse,
          reason: 'С фильтром "За все время" нет наложения');
    });

    // ──────────────────────────────────────────────────────────────────────
    // Тест 10: RevenueDynamicsChart содержит заголовок "Динамика показателей"
    // ──────────────────────────────────────────────────────────────────────
    testWidgets('RevenueDynamicsChart содержит заголовок "Динамика показателей"',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _goToReports(tester);

      // Скроллим вниз чтобы RevenueDynamicsChart был видим
      final scrollView = find.byType(SingleChildScrollView);
      await tester.drag(scrollView, const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(find.text('Динамика показателей'), findsOneWidget);
    });

    // ──────────────────────────────────────────────────────────────────────
    // Тест 11: Все 5 блоков присутствуют на странице
    // ──────────────────────────────────────────────────────────────────────
    testWidgets('Все 5 блоков отчёта присутствуют на странице',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _goToReports(tester);

      expect(find.byType(FinanceDashboardCard), findsOneWidget,
          reason: 'FinanceDashboardCard присутствует');
      expect(find.byType(FinancePieChart), findsOneWidget,
          reason: 'FinancePieChart присутствует');
      expect(find.byType(KpiCards), findsOneWidget,
          reason: 'KpiCards присутствует');
      expect(find.byType(PaymentTariffCard), findsOneWidget,
          reason: 'PaymentTariffCard присутствует');
      expect(find.byType(RevenueDynamicsChart), findsOneWidget,
          reason: 'RevenueDynamicsChart присутствует');
    });
  });
}
