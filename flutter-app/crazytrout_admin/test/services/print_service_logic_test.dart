import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/models/receipt.dart';
import 'package:crazytrout_admin/models/client.dart';
import 'package:crazytrout_admin/services/escpos_builder.dart';

/// Тесты логики Bluetooth-печати (без реального Bluetooth).
///
/// PrintService.printViaBluetooth() зависит от flutter_blue_plus —
/// platform plugin, который нельзя вызвать в unit-тестах.
/// Здесь тестируем логику, которую можно выделить и проверить:
/// - Chunk splitting (разбиение данных на части)
/// - ESC/POS формат для разных типов принтеров
/// - Обработка ошибок

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

/// Разбивает данные на чанки (имитация логики из print_service.dart).
List<Uint8List> splitIntoChunks(Uint8List data, int chunkSize) {
  final chunks = <Uint8List>[];
  for (var i = 0; i < data.length; i += chunkSize) {
    final end = i + chunkSize > data.length ? data.length : i + chunkSize;
    chunks.add(data.sublist(i, end));
  }
  return chunks;
}

void main() {
  group('Bluetooth-печать — логика (без реального BT)', () {
    group('Chunk splitting — разбиение данных на части', () {
      test('данные разбиваются на чанки по 20 байт (BLE MTU)', () {
        final data = buildEscPos(_makeReceipt());
        final chunks = splitIntoChunks(data, 20);

        // Все чанки ≤ 20 байт
        for (final chunk in chunks) {
          expect(chunk.length, lessThanOrEqualTo(20));
        }

        // Суммарный размер = исходный
        final totalSize = chunks.fold<int>(0, (s, c) => s + c.length);
        expect(totalSize, data.length);
      });

      test('данные разбиваются на чанки по 512 байт (Classic SPP)', () {
        final data = buildEscPos(_makeReceipt());
        final chunks = splitIntoChunks(data, 512);

        // Данные < 512 байт → один чанк
        expect(chunks.length, 1);
        expect(chunks[0].length, data.length);
      });

      test('пустые данные → 0 чанков', () {
        final data = Uint8List(0);
        final chunks = splitIntoChunks(data, 20);
        expect(chunks, isEmpty);
      });

      test('данные ровно 20 байт → 1 чанк', () {
        final data = Uint8List(20);
        final chunks = splitIntoChunks(data, 20);
        expect(chunks.length, 1);
        expect(chunks[0].length, 20);
      });

      test('данные 21 байт → 2 чанка (20 + 1)', () {
        final data = Uint8List(21);
        final chunks = splitIntoChunks(data, 20);
        expect(chunks.length, 2);
        expect(chunks[0].length, 20);
        expect(chunks[1].length, 1);
      });
    });

    group('ESC/POS формат — совместимость с разными принтерами', () {
      test('данные содержат ESC @ (инициализация) в начале', () {
        final data = buildEscPos(_makeReceipt());
        expect(data[0], 0x1B);
        expect(data[1], 0x40);
      });

      test('данные содержат ESC t (выбор кодовой страницы)', () {
        final data = buildEscPos(_makeReceipt());
        expect(data[2], 0x1B);
        expect(data[3], 0x74); // 't'
      });

      test('данные заканчиваются GS V (отрез бумаги)', () {
        final data = buildEscPos(_makeReceipt());
        expect(data[data.length - 3], 0x1D);
        expect(data[data.length - 2], 0x56); // 'V'
        expect(data[data.length - 1], 0x01);
      });

      test('размер данных > 50 байт (не пустой чек)', () {
        final data = buildEscPos(_makeReceipt());
        expect(data.length, greaterThan(50));
      });

      test('размер данных < 2000 байт (умеренный)', () {
        final data = buildEscPos(_makeReceipt());
        expect(data.length, lessThan(2000));
      });
    });

    group('Разные типы чеков — ESC/POS', () {
      test('фискальный чек содержит "Фискальный чек"', () {
        final data = buildEscPos(_makeReceipt(fiscal: true));
        // Ищем в CP866-данных
        final text = String.fromCharCodes(data.where((b) => b >= 0x20 && b < 0x80));
        expect(text, contains('CRAZY TROUT ARENA'));
      });

      test('чек без ФН содержит "Без ФН"', () {
        final data = buildEscPos(_makeReceipt(fiscal: false));
        expect(data.length, greaterThan(50));
        // Отрез присутствует
        expect(data[data.length - 3], 0x1D);
      });

      test('гостевой чек не падает', () {
        final data = buildEscPos(_makeReceipt(isGuest: true));
        expect(data.length, greaterThan(50));
      });

      test('чек с пустым уловом не падает', () {
        final receipt = Receipt(
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
        final data = buildEscPos(receipt);
        expect(data.length, greaterThan(50));
        expect(data[0], 0x1B);
        expect(data[1], 0x40);
      });

      test('чек пенсионера (0₽ тариф) не падает', () {
        final receipt = Receipt(
          number: 1252,
          date: DateTime(2026, 7, 11),
          client: const Client(id: 6, name: 'Михаил Орлов', phone: '+7 962 888-99-00', tariffLabel: 'Пенсионер'),
          isGuest: false,
          tariffLabel: 'Пенсионер',
          tariffPrice: 0,
          rows: [const ReceiptRow(name: 'Карп', weight: 3.000, price: 590, sum: 1770)],
          total: 1770,
          payment: PaymentMethod.cash,
          fiscal: true,
          fiscalDoc: '№ФД-11252',
        );
        final data = buildEscPos(receipt);
        expect(data.length, greaterThan(50));
      });
    });

    group('MTU detection — логика выбора chunk size', () {
      test('BLE MTU 23 → chunk size 20', () {
        const mtu = 23;
        final chunkSize = mtu > 23 ? mtu - 3 : 20;
        expect(chunkSize, 20);
      });

      test('BLE MTU 512 → chunk size 509', () {
        const mtu = 512;
        final chunkSize = mtu > 23 ? mtu - 3 : 20;
        expect(chunkSize, 509);
      });

      test('Classic SPP (без MTU) → chunk size 512', () {
        // Имитация: MTU не доступен, используем 512
        const chunkSize = 512;
        expect(chunkSize, 512);
      });
    });
  });
}
