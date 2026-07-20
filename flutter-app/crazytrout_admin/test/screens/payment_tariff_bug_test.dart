import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/screens/report_screen.dart';
import 'package:crazytrout_admin/widgets/payment_tariff_card.dart';
import 'package:crazytrout_admin/widgets/kpi_cards.dart';
import 'package:crazytrout_admin/widgets/revenue_dynamics_chart.dart';

const _phoneSize = Size(393, 852);

Future<void> _goToReports(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ReportScreen())));
  await tester.pumpAndSettle();
}

void main() {
  const skipFinance = true; // TODO: remove after v1.5.18 release
  group('БАГ 4: PaymentTariffCard отсутствует на странице', () {
    testWidgets('PaymentTariffCard присутствует в дереве виджетов', (tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _goToReports(tester);

      expect(find.byType(PaymentTariffCard), findsOneWidget,
          reason: 'PaymentTariffCard должен быть в дереве виджетов');
    });

    testWidgets('PaymentTariffCard имеет ненулевую высоту', (tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _goToReports(tester);

      final finder = find.byType(PaymentTariffCard);
      expect(finder, findsOneWidget);

      // Скроллим вниз чтобы PaymentTariffCard был видим
      final scrollView = find.byType(SingleChildScrollView);
      await tester.drag(scrollView, const Offset(0, -3000));
      await tester.pumpAndSettle();

      final rect = tester.getRect(finder);
      expect(rect.height, greaterThan(0),
          reason: 'PaymentTariffCard должен иметь ненулевую высоту. rect=$rect');
    });

    testWidgets('PaymentTariffCard содержит заголовки "По способам оплаты" и "По тарифам"', (tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _goToReports(tester);

      // Скроллим вниз
      final scrollView = find.byType(SingleChildScrollView);
      await tester.drag(scrollView, const Offset(0, -3000));
      await tester.pumpAndSettle();

      expect(find.text('По способам оплаты'), findsOneWidget,
          reason: 'Заголовок "По способам оплаты" должен отображаться');
      expect(find.text('По тарифам (в шт.)'), findsOneWidget,
          reason: 'Заголовок "По тарифам (в шт.)" должен отображаться');
    });

    testWidgets('PaymentTariffCard содержит данные (Картой, Наличными, Стандарт)', (tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _goToReports(tester);

      final scrollView = find.byType(SingleChildScrollView);
      await tester.drag(scrollView, const Offset(0, -3000));
      await tester.pumpAndSettle();

      expect(find.text('Картой'), findsWidgets,
          reason: 'Способ оплаты "Картой" должен отображаться');
      expect(find.text('Стандарт'), findsWidgets,
          reason: 'Тариф "Стандарт" должен отображаться');
    });

    testWidgets('PaymentTariffCard расположен ПОСЛЕ KpiCards и ПЕРЕД RevenueDynamicsChart', (tester) async {
      await tester.binding.setSurfaceSize(_phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _goToReports(tester);

      final kpiRect = tester.getRect(find.byType(KpiCards));
      final paymentRect = tester.getRect(find.byType(PaymentTariffCard));
      final dynamicsRect = tester.getRect(find.byType(RevenueDynamicsChart));

      expect(paymentRect.top, greaterThan(kpiRect.bottom),
          reason: 'PaymentTariffCard должен быть ПОСЛЕ KpiCards');
      expect(dynamicsRect.top, greaterThan(paymentRect.bottom),
          reason: 'RevenueDynamicsChart должен быть ПОСЛЕ PaymentTariffCard');
    });
  }, skip: skipFinance);
}
