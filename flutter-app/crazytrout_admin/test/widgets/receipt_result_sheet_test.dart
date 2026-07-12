import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/models/client.dart';
import 'package:crazytrout_admin/models/receipt.dart';
import 'package:crazytrout_admin/widgets/receipt_result_sheet.dart';

Receipt _makeReceipt({
  bool fiscal = true,
  PaymentMethod payment = PaymentMethod.card,
  bool isGuest = false,
}) {
  return Receipt(
    number: 1248,
    date: DateTime(2026, 7, 11, 15, 30),
    client: isGuest
        ? null
        : const Client(id: 1, name: 'Иван Иванов', phone: '+7 925 123-45-67', tariffLabel: 'Стандарт'),
    isGuest: isGuest,
    tariffLabel: isGuest ? 'Гостевой' : 'Стандарт',
    tariffPrice: isGuest ? 500 : 750,
    rows: const [
      ReceiptRow(name: 'Осётр', weight: 2.500, price: 1890, sum: 4725),
      ReceiptRow(name: 'Карп', weight: 1.000, price: 590, sum: 590),
    ],
    total: 6065,
    payment: payment,
    fiscal: fiscal,
    fiscalDoc: fiscal ? '№ФД-11248' : null,
  );
}

void main() {
  group('ReceiptResultSheet — шторка с чеком', () {
    testWidgets('отображает заголовок "Чек создан"', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showReceiptResultSheet(ctx, _makeReceipt()),
            child: const Text('Show'),
          ),
        )),
      ));
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.text('Чек создан'), findsOneWidget);
    });

    testWidgets('отображает "CRAZY TROUT ARENA"', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showReceiptResultSheet(ctx, _makeReceipt()),
            child: const Text('Show'),
          ),
        )),
      ));
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.text('CRAZY TROUT ARENA'), findsOneWidget);
    });

    testWidgets('отображает номер чека', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showReceiptResultSheet(ctx, _makeReceipt()),
            child: const Text('Show'),
          ),
        )),
      ));
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.textContaining('1248'), findsWidgets);
    });

    testWidgets('отображает клиента', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showReceiptResultSheet(ctx, _makeReceipt()),
            child: const Text('Show'),
          ),
        )),
      ));
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Иван'), findsWidgets);
    });

    testWidgets('отображает "ИТОГО: 6 065 ₽"', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showReceiptResultSheet(ctx, _makeReceipt()),
            child: const Text('Show'),
          ),
        )),
      ));
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.textContaining('6 065'), findsWidgets);
    });

    testWidgets('отображает кнопку Bluetooth-печати', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showReceiptResultSheet(ctx, _makeReceipt()),
            child: const Text('Show'),
          ),
        )),
      ));
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.text('Найти принтер и распечатать'), findsOneWidget);
    });

    testWidgets('отображает кнопку AirPrint', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showReceiptResultSheet(ctx, _makeReceipt()),
            child: const Text('Show'),
          ),
        )),
      ));
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.text('Печать через AirPrint'), findsOneWidget);
    });

    testWidgets('отображает "Готово · новый чек"', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showReceiptResultSheet(ctx, _makeReceipt()),
            child: const Text('Show'),
          ),
        )),
      ));
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.text('Готово · новый чек'), findsOneWidget);
    });

    testWidgets('гостевой чек показывает "Гость (без анкеты)"', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showReceiptResultSheet(ctx, _makeReceipt(isGuest: true)),
            child: const Text('Show'),
          ),
        )),
      ));
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Гость'), findsWidgets);
    });

    testWidgets('чек без ФН показывает "Без ФН"', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showReceiptResultSheet(ctx, _makeReceipt(fiscal: false)),
            child: const Text('Show'),
          ),
        )),
      ));
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Без ФН'), findsWidgets);
    });
  });
}
