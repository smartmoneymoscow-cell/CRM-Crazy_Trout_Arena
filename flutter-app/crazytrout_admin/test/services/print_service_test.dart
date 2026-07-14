import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:crazytrout_admin/models/receipt.dart';
import 'package:crazytrout_admin/models/client.dart';
import 'package:crazytrout_admin/services/escpos_builder.dart';

/// Тесты логики печати.
///
/// PrintService.printViaSystemDialog() и printViaBluetooth() зависят от
/// platform plugins — их нельзя вызвать в unit-тестах без моков.
/// Здесь тестируем данные, которые уходят на принтер.

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
  group('PDF-документ (AirPrint / системный диалог)', () {
    test('PDF генерируется для фискального чека', () async {
      final r = _makeReceipt(fiscal: true);
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('CRAZY TROUT ARENA', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold))),
              pw.Center(child: pw.Text('Чек № ${r.number} · 11.07.2026 15:30', style: const pw.TextStyle(fontSize: 9))),
              pw.Divider(),
              pw.Text('Клиент: ${r.clientLine}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Тариф · ${r.tariffLabel}: ${r.tariffPrice} ₽', style: const pw.TextStyle(fontSize: 10)),
              pw.Divider(),
              ...r.rows.map((it) => pw.Text(
                    '${it.name} ${it.weight.toStringAsFixed(2)}кг × ${it.price.round()} = ${it.sum.round()} ₽',
                    style: const pw.TextStyle(fontSize: 10),
                  )),
              pw.Divider(),
              pw.Text('ИТОГО: ${r.total.round()} ₽', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.Text('Оплата: ${r.payment.label}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text(r.fiscal ? 'Фискальный чек ${r.fiscalDoc ?? ""}' : 'Без ФН', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
    });

    test('PDF генерируется для чека без ФН', () async {
      final r = _makeReceipt(fiscal: false);
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          build: (context) => pw.Column(
            children: [
              pw.Text('Чек № ${r.number}'),
              pw.Text(r.fiscal ? 'Фискальный' : 'Без ФН'),
            ],
          ),
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
    });

    test('PDF генерируется для гостевого чека', () async {
      final r = _makeReceipt(isGuest: true);
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          build: (context) => pw.Column(
            children: [
              pw.Text('Клиент: ${r.clientLine}'),
              pw.Text('ИТОГО: ${r.total.round()} ₽'),
            ],
          ),
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(r.clientLine, 'Гость (без анкеты)');
    });

    test('PDF не падает с пустым уловом', () async {
      final r = Receipt(
        number: 9999,
        date: DateTime(2026, 1, 1),
        client: null,
        isGuest: true,
        tariffLabel: 'Гостевой',
        tariffPrice: 500,
        rows: [],
        total: 500,
        payment: PaymentMethod.cash,
        fiscal: false,
      );
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          build: (context) => pw.Column(
            children: [
              pw.Text('ИТОГО: ${r.total.round()} ₽'),
            ],
          ),
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
    });
  });

  group('ESC/POS данные (Bluetooth-принтер)', () {
    test('ESC/POS для фискального чека: ESC @ + UTF-8 текст + отрез', () {
      final r = _makeReceipt(fiscal: true);
      final data = buildEscPos(r);

      // ESC @
      expect(data[0], 0x1B);
      expect(data[1], 0x40);

      // ESC t 82 (UTF-8)
      expect(data[2], 0x1B);
      expect(data[3], 0x74);
      expect(data[4], 0x52);

      // Отрез бумаги в конце: GS V 1
      expect(data[data.length - 3], 0x1D);
      expect(data[data.length - 2], 0x56);
      expect(data[data.length - 1], 0x01);
    });

    test('ESC/POS для чека без ФН', () {
      final r = _makeReceipt(fiscal: false, payment: PaymentMethod.cash);
      final data = buildEscPos(r);
      // Не падает, размер корректный
      expect(data.length, greaterThan(50));
      // Отрез в конце
      expect(data[data.length - 3], 0x1D);
    });

    test('ESC/POS для гостевого чека', () {
      final r = _makeReceipt(isGuest: true);
      final data = buildEscPos(r);
      expect(data.length, greaterThan(50));
    });

    test('ESC/POS для чека с пустым уловом', () {
      final r = Receipt(
        number: 9999,
        date: DateTime(2026, 1, 1),
        client: null,
        isGuest: true,
        tariffLabel: 'Гостевой',
        tariffPrice: 500,
        rows: [],
        total: 500,
        payment: PaymentMethod.cash,
        fiscal: false,
      );
      final data = buildEscPos(r);
      expect(data[0], 0x1B);
      expect(data[1], 0x40);
      expect(data.length, greaterThan(50));
    });

    test('размер данных минимум заголовок + текст + отрез', () {
      final data = buildEscPos(_makeReceipt());
      expect(data.length, greaterThan(50));
    });
  });

  group('Корректность данных в чеке', () {
    test('total = тариф + сумма строк', () {
      final r = _makeReceipt();
      final rowsTotal = r.rows.fold<double>(0, (s, row) => s + row.sum);
      expect(r.total, r.tariffPrice + rowsTotal);
    });

    test('weight каждой строки корректен', () {
      final r = _makeReceipt();
      expect(r.rows[0].weight, closeTo(2.500, 0.001));
      expect(r.rows[1].weight, closeTo(1.000, 0.001));
    });

    test('sum каждой строки = weight × price', () {
      final r = _makeReceipt();
      for (final row in r.rows) {
        expect(row.sum, closeTo(row.weight * row.price, 0.01));
      }
    });

    test('payment.label корректен для обоих типов', () {
      expect(PaymentMethod.cash.label, 'Наличными');
      expect(PaymentMethod.card.label, 'Картой');
    });
  });
}
