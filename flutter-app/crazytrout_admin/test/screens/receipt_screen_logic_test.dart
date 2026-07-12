import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/data/demo_data.dart';
import 'package:crazytrout_admin/models/catch_row.dart';
import 'package:crazytrout_admin/models/client.dart';
import 'package:crazytrout_admin/models/receipt.dart';
import 'package:crazytrout_admin/models/tariff.dart';
import 'package:crazytrout_admin/utils/format.dart';

/// Имитация логики экрана ReceiptScreen для тестирования.
/// В реальном приложении это приватные методы State-класса,
/// но для тестирования вынесены в standalone-функции.

/// Поиск клиентов (из receipt_screen.dart).
List<Client> searchClients(String query) {
  if (query.trim().isEmpty) return [];
  final q = query.toLowerCase();
  return kDemoClients
      .where((c) => c.name.toLowerCase().contains(q) || c.phone.contains(q))
      .toList();
}

/// Выбор клиента — подстановка тарифа (из receipt_screen.dart).
Tariff selectClientTariff(Client c) {
  final matched = kTariffs.where((t) => t.label == c.tariffLabel);
  return matched.isNotEmpty ? matched.first : kTariffs.first;
}

/// Выбор гостя (из receipt_screen.dart).
Tariff selectGuestTariff() {
  return kTariffs.firstWhere((t) => t.id == 'guest');
}

/// Подсчёт суммы улова (из receipt_screen.dart).
double catchTotal(List<CatchRow> rows) {
  return rows.fold(0.0, (s, r) => s + r.sum);
}

/// Итого = тариф + улов (из receipt_screen.dart).
double total(Tariff tariff, List<CatchRow> rows) {
  return tariff.price + catchTotal(rows);
}

/// Создание чека (из receipt_screen.dart _submit).
Receipt createReceipt({
  required int receiptSeq,
  required Client? client,
  required bool isGuest,
  required Tariff tariff,
  required List<CatchRow> rows,
  required PaymentMethod payment,
  required bool fiscal,
}) {
  return Receipt(
    number: receiptSeq,
    date: DateTime.now(),
    client: client,
    isGuest: isGuest,
    tariffLabel: tariff.label,
    tariffPrice: tariff.price,
    rows: rows
        .map((r) => ReceiptRow(name: r.species, weight: r.weight, price: r.pricePerKg, sum: r.sum))
        .toList(),
    total: total(tariff, rows),
    payment: payment,
    fiscal: fiscal,
    fiscalDoc: fiscal ? '№ФД-${10000 + receiptSeq}' : null,
  );
}

void main() {
  group('ReceiptScreen — бизнес-логика', () {
    group('_money() — форматирование сумм', () {
      test('0 → "0 ₽"', () {
        expect(money(0), '0 ₽');
      });

      test('100 → "100 ₽"', () {
        expect(money(100), '100 ₽');
      });

      test('1000 → "1 000 ₽"', () {
        expect(money(1000), '1 000 ₽');
      });

      test('1234567 → "1 234 567 ₽"', () {
        expect(money(1234567), '1 234 567 ₽');
      });

      test('750.0 → "750 ₽"', () {
        expect(money(750.0), '750 ₽');
      });

      test('999.6 → "1 000 ₽" (округление)', () {
        expect(money(999.6), '1 000 ₽');
      });
    });

    group('_search() — поиск клиентов', () {
      test('пустая строка → пустой список', () {
        expect(searchClients(''), isEmpty);
      });

      test('пробелы → пустой список', () {
        expect(searchClients('   '), isEmpty);
      });

      test('"иван" находит Ивана Иванова', () {
        final results = searchClients('иван');
        expect(results.length, 1);
        expect(results.first.name, 'Иван Иванов');
      });

      test('"иван" нечувствителен к регистру', () {
        expect(searchClients('ИВАН').length, 1);
        expect(searchClients('Иван').length, 1);
      });

      test('"925" находит по телефону', () {
        final results = searchClients('925');
        expect(results, isNotEmpty);
        expect(results.first.phone, contains('925'));
      });

      test('"кошкин" находит по фамилии', () {
        final results = searchClients('кошкин');
        expect(results.length, 1);
        expect(results.first.name, contains('Кошкин'));
      });

      test('"несуществующий" → пустой список', () {
        expect(searchClients('zzzzzzzzz'), isEmpty);
      });

      test('"+" находит всех (все телефоны начинаются с +)', () {
        final results = searchClients('+');
        expect(results.length, kDemoClients.length);
      });
    });

    group('_selectClient() — выбор клиента', () {
      test('выбор Ивана → тариф "Стандарт"', () {
        final client = kDemoClients.firstWhere((c) => c.id == 1);
        final tariff = selectClientTariff(client);
        expect(tariff.label, 'Стандарт');
        expect(tariff.price, 750);
      });

      test('выбор Михаила → тариф "Пенсионер"', () {
        final client = kDemoClients.firstWhere((c) => c.id == 6);
        final tariff = selectClientTariff(client);
        expect(tariff.label, 'Пенсионер');
        expect(tariff.price, 0);
      });

      test('выбор гостя → тариф "Гостевой" 500₽', () {
        final tariff = selectGuestTariff();
        expect(tariff.id, 'guest');
        expect(tariff.label, 'Гостевой');
        expect(tariff.price, 500);
      });
    });

    group('_addRow() / _removeRow() — управление уловом', () {
      test('добавление строки увеличивает список', () {
        final rows = <CatchRow>[];
        rows.add(CatchRow(id: 1, species: 'Карп', kg: 0, grams: 0, pricePerKg: 590));
        expect(rows.length, 1);
      });

      test('удаление строки уменьшает список', () {
        final rows = [
          CatchRow(id: 1, species: 'Карп', kg: 0, grams: 0, pricePerKg: 590),
          CatchRow(id: 2, species: 'Осётр', kg: 0, grams: 0, pricePerKg: 1890),
        ];
        rows.removeWhere((r) => r.id == 1);
        expect(rows.length, 1);
        expect(rows.first.species, 'Осётр');
      });

      test('удаление несуществующей строки — ничего не меняется', () {
        final rows = [
          CatchRow(id: 1, species: 'Карп', kg: 0, grams: 0, pricePerKg: 590),
        ];
        rows.removeWhere((r) => r.id == 999);
        expect(rows.length, 1);
      });
    });

    group('_catchTotal / _total — подсчёт сумм', () {
      test('пустой улов → 0₽', () {
        expect(catchTotal([]), 0);
      });

      test('одна рыба 2.5кг × 1890₽ = 4725₽', () {
        final rows = [CatchRow(id: 1, species: 'Осётр', kg: 2, grams: 500, pricePerKg: 1890)];
        expect(catchTotal(rows), closeTo(4725, 0.01));
      });

      test('две рыбы: 4725 + 590 = 5315₽', () {
        final rows = [
          CatchRow(id: 1, species: 'Осётр', kg: 2, grams: 500, pricePerKg: 1890),
          CatchRow(id: 2, species: 'Карп', kg: 1, grams: 0, pricePerKg: 590),
        ];
        expect(catchTotal(rows), closeTo(5315, 0.01));
      });

      test('итого = тариф + улов', () {
        final tariff = kTariffs.first; // Стандарт 750₽
        final rows = [CatchRow(id: 1, species: 'Карп', kg: 1, grams: 0, pricePerKg: 590)];
        expect(total(tariff, rows), 1340); // 750 + 590
      });

      test('Пенсионер: итого = только улов (тариф 0₽)', () {
        final tariff = kTariffs.firstWhere((t) => t.id == 'pensioner');
        final rows = [CatchRow(id: 1, species: 'Карп', kg: 1, grams: 0, pricePerKg: 590)];
        expect(total(tariff, rows), 590);
      });
    });

    group('_submit() — создание чека', () {
      test('фискальный чек с клиентом', () {
        final receipt = createReceipt(
          receiptSeq: 1248,
          client: kDemoClients.first,
          isGuest: false,
          tariff: kTariffs.first,
          rows: [CatchRow(id: 1, species: 'Карп', kg: 1, grams: 0, pricePerKg: 590)],
          payment: PaymentMethod.card,
          fiscal: true,
        );
        expect(receipt.number, 1248);
        expect(receipt.fiscal, isTrue);
        expect(receipt.fiscalDoc, contains('ФД'));
        expect(receipt.clientLine, contains('Иван'));
      });

      test('гостевой чек без ФН', () {
        final receipt = createReceipt(
          receiptSeq: 1249,
          client: null,
          isGuest: true,
          tariff: selectGuestTariff(),
          rows: [],
          payment: PaymentMethod.cash,
          fiscal: false,
        );
        expect(receipt.isGuest, isTrue);
        expect(receipt.fiscal, isFalse);
        expect(receipt.fiscalDoc, isNull);
        expect(receipt.clientLine, 'Гость (без анкеты)');
      });

      test('чек пенсионера', () {
        final receipt = createReceipt(
          receiptSeq: 1250,
          client: kDemoClients.firstWhere((c) => c.id == 6),
          isGuest: false,
          tariff: kTariffs.firstWhere((t) => t.id == 'pensioner'),
          rows: [CatchRow(id: 1, species: 'Карп', kg: 3, grams: 0, pricePerKg: 590)],
          payment: PaymentMethod.cash,
          fiscal: true,
        );
        expect(receipt.tariffPrice, 0);
        expect(receipt.total, closeTo(1770, 0.01));
      });

      test('чек с пустым уловом', () {
        final receipt = createReceipt(
          receiptSeq: 1251,
          client: kDemoClients.first,
          isGuest: false,
          tariff: kTariffs.first,
          rows: [],
          payment: PaymentMethod.card,
          fiscal: true,
        );
        expect(receipt.rows, isEmpty);
        expect(receipt.total, 750);
      });
    });
  });
}
