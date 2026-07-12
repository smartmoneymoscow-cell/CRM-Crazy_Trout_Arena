import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/models/receipt.dart';
import 'package:crazytrout_admin/models/client.dart';
import 'package:crazytrout_admin/services/escpos_builder.dart';

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

/// Декодирует CP866 байты в строку (обратная функция к _encodeCp866).
String _decodeCp866(List<int> bytes) {
  final result = StringBuffer();
  for (final b in bytes) {
    if (b >= 0x80 && b <= 0x9F) {
      // А-Я: 0x80..0x9F → U+0410..U+042F
      result.writeCharCode(0x0410 + (b - 0x80));
    } else if (b >= 0xA0 && b <= 0xAF) {
      // а-п: 0xA0..0xAF → U+0430..U+043F
      result.writeCharCode(0x0430 + (b - 0xA0));
    } else if (b >= 0xE0 && b <= 0xEF) {
      // р-я: 0xE0..0xEF → U+0440..U+044F
      result.writeCharCode(0x0440 + (b - 0xE0));
    } else if (b == 0xF0) {
      result.write('Ё');
    } else if (b == 0xF1) {
      result.write('ё');
    } else {
      // Латиница и ASCII-символы
      result.writeCharCode(b);
    }
  }
  return result.toString();
}

/// Извлекает текстовую часть из ESC/POS данных (пропускает ESC-команды).
String _extractText(Uint8List data) {
  // Пропускаем начальные ESC-команды (ESC @, ESC t, ESC a, ESC E, ESC !)
  // ищем начало текста после последней ESC-последовательности перед первым
  // печатаемым символом
  final textBytes = <int>[];
  var i = 0;
  while (i < data.length) {
    if (data[i] == 0x1B || data[i] == 0x1D) {
      // ESC- или GS-команда — пропускаем
      i++;
      if (i < data.length) i++; // минимум 1 параметр
      continue;
    }
    if (data[i] == 0x0A) {
      textBytes.add(data[i]);
      i++;
      continue;
    }
    // Текстовый байт
    textBytes.add(data[i]);
    i++;
  }
  return _decodeCp866(textBytes);
}

void main() {
  group('ESC/POS builder — байты для Bluetooth-принтера', () {
    group('Фискальный чек', () {
      late Uint8List data;
      late String text;

      setUp(() {
        data = buildEscPos(_makeReceipt(fiscal: true));
        text = _extractText(data);
      });

      test('начинается с ESC @ (0x1B, 0x40) — сброс принтера', () {
        expect(data[0], 0x1B);
        expect(data[1], 0x40);
      });

      test('содержит команду выбора CP866 (ESC t 0x11)', () {
        // ESC t 17 — выбор таблицы кодов CP866
        expect(data[2], 0x1B);
        expect(data[3], 0x74); // 't'
        expect(data[4], 0x11); // 17 = CP866
      });

      test('заканчивается командой отреза бумаги (GS V 1)', () {
        // GS V 1 = partial cut
        expect(data[data.length - 3], 0x1D);
        expect(data[data.length - 2], 0x56); // 'V'
        expect(data[data.length - 1], 0x01);
      });

      test('содержит заголовок "CRAZY TROUT ARENA"', () {
        expect(text, contains('CRAZY TROUT ARENA'));
      });

      test('содержит русский текст "Чек" и номер 1248', () {
        // CP866-декодирование может отличаться для № — проверяем отдельно
        expect(text, contains('Чек'));
        expect(text, contains('1248'));
      });

      test('содержит разделитель "---"', () {
        expect(text, contains('--------------------------------'));
      });

      test('содержит строку "Осётр" с весом 2.50кг и ценой 1890', () {
        expect(text, contains('Осётр'));
        expect(text, contains('2.50кг'));
        expect(text, contains('1890'));
      });

      test('содержит строку "Карп" с весом 1.00кг и ценой 590', () {
        expect(text, contains('Карп'));
        expect(text, contains('1.00кг'));
        expect(text, contains('590'));
      });

      test('содержит "ИТОГО: 6065 ₽"', () {
        expect(text, contains('ИТОГО: 6065'));
      });

      test('содержит способ оплаты "Картой"', () {
        expect(text, contains('Оплата: Картой'));
      });

      test('содержит тип чека "Фискальный"', () {
        expect(text, contains('Фискальный чек'));
      });

      test('размер данных 50–2000 байт', () {
        expect(data.length, greaterThan(50));
        expect(data.length, lessThan(2000));
      });
    });

    group('Чек без ФН', () {
      late Uint8List data;
      late String text;

      setUp(() {
        data = buildEscPos(_makeReceipt(fiscal: false, payment: PaymentMethod.cash));
        text = _extractText(data);
      });

      test('содержит "Оплата: Наличными"', () {
        expect(text, contains('Оплата: Наличными'));
      });

      test('содержит "ИТОГО: 6065"', () {
        expect(text, contains('ИТОГО: 6065'));
      });

      test('содержит "Без ФН"', () {
        expect(text, contains('Без ФН'));
      });
    });

    group('Чек гостя', () {
      test('содержит "ИТОГО: 1940"', () {
        final receipt = Receipt(
          number: 1250,
          date: DateTime(2026, 7, 11),
          client: null,
          isGuest: true,
          tariffLabel: 'Гостевой',
          tariffPrice: 500,
          rows: [const ReceiptRow(name: 'Форель', weight: 1.200, price: 1200, sum: 1440)],
          total: 1940,
          payment: PaymentMethod.card,
          fiscal: true,
          fiscalDoc: '№ФД-11250',
        );
        final data = buildEscPos(receipt);
        final text = _extractText(data);
        expect(text, contains('ИТОГО: 1940'));
        expect(text, contains('1.20кг'));
        expect(text, contains('Форель'));
      });

      test('содержит "Гость (без анкеты)"', () {
        final receipt = Receipt(
          number: 1250,
          date: DateTime(2026, 7, 11),
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
        final text = _extractText(data);
        expect(text, contains('Гость (без анкеты)'));
      });
    });

    group('Чек с пустым уловом', () {
      test('не падает, содержит ИТОГО = тариф', () {
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
        final text = _extractText(data);
        expect(text, contains('ИТОГО: 500'));
        // ESC @ в начале
        expect(data[0], 0x1B);
        expect(data[1], 0x40);
        // Отрез в конце
        expect(data[data.length - 3], 0x1D);
        expect(data[data.length - 2], 0x56);
      });
    });

    group('Кодировка CP866', () {
      test('кириллица закодирована корректно (не UTF-8)', () {
        final data = buildEscPos(_makeReceipt());
        // Проверяем что данные НЕ валидны как UTF-8 для кириллицы
        // (байты 0x80-0xFF используются для русских букв в CP866)
        // Но должны корректно декодироваться через _decodeCp866
        final text = _extractText(data);
        expect(text, contains('Чек'));
        expect(text, contains('Клиент'));
        expect(text, contains('Тариф'));
      });

      test('команда отреза присутствует', () {
        final data = buildEscPos(_makeReceipt());
        // Ищем GS V в данных
        var foundCut = false;
        for (var i = 0; i < data.length - 2; i++) {
          if (data[i] == 0x1D && data[i + 1] == 0x56) {
            foundCut = true;
            break;
          }
        }
        expect(foundCut, isTrue);
      });
    });
  });
}
