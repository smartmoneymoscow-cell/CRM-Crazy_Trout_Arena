import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/data/demo_data.dart';
import 'package:crazytrout_admin/models/client.dart';

/// Имитация логики поиска клиента по QR-коду из receipt_screen.dart.
/// Вынесена в отдельную функцию для тестирования.
Client? findClientByQr(String code) {
  if (code.trim().isEmpty) return null;

  // Ищем по id из QR (формат: "client:<id>" или просто id)
  final idStr = code.contains(':') ? code.split(':').last : code;
  final clientId = int.tryParse(idStr);

  if (clientId != null) {
    final match = kDemoClients.where((c) => c.id == clientId);
    if (match.isNotEmpty) return match.first;
  }

  // Фолбэк: ищем как строку в имени/телефоне
  final lower = code.toLowerCase();
  final match = kDemoClients.where(
    (c) => c.name.toLowerCase().contains(lower) || c.phone.contains(code),
  );
  return match.isNotEmpty ? match.first : null;
}

void main() {
  group('QR-сканер — поиск клиента по QR-коду', () {
    group('Поиск по id', () {
      test('QR "client:1" находит Ивана Иванова (id=1)', () {
        final client = findClientByQr('client:1');
        expect(client, isNotNull);
        expect(client!.name, 'Иван Иванов');
        expect(client.id, 1);
      });

      test('QR "client:4" находит Анну Морозову (id=4)', () {
        final client = findClientByQr('client:4');
        expect(client, isNotNull);
        expect(client!.name, 'Анна Морозова');
        expect(client.id, 4);
      });

      test('QR "1" (просто число) находит Ивана Иванова', () {
        final client = findClientByQr('1');
        expect(client, isNotNull);
        expect(client!.name, 'Иван Иванов');
      });

      test('QR "7" находит Олега Сидорова', () {
        final client = findClientByQr('7');
        expect(client, isNotNull);
        expect(client!.name, 'Олег Сидоров');
      });
    });

    group('Поиск по имени', () {
      test('QR "иван" находит Ивана Иванова', () {
        final client = findClientByQr('иван');
        expect(client, isNotNull);
        expect(client!.name, contains('Иван'));
      });

      test('QR "ИВАН" (верхний регистр) находит Ивана Иванова', () {
        final client = findClientByQr('ИВАН');
        expect(client, isNotNull);
        expect(client!.name, contains('Иван'));
      });

      test('QR "кошкин" находит Алексея Кошкина', () {
        final client = findClientByQr('кошкин');
        expect(client, isNotNull);
        expect(client!.name, contains('Кошкин'));
      });
    });

    group('Поиск по телефону', () {
      test('QR "+7 925 123-45-67" находит Ивана Иванова', () {
        final client = findClientByQr('+7 925 123-45-67');
        expect(client, isNotNull);
        expect(client!.name, 'Иван Иванов');
      });

      test('QR "916" находит Алексея Кошкин (содержит 916)', () {
        final client = findClientByQr('916');
        expect(client, isNotNull);
        expect(client!.phone, contains('916'));
      });
    });

    group('Неизвестный QR-код', () {
      test('QR "несуществующий" возвращает null', () {
        final client = findClientByQr('несуществующий');
        expect(client, isNull);
      });

      test('QR "client:999" возвращает null (нет такого id)', () {
        final client = findClientByQr('client:999');
        expect(client, isNull);
      });

      test('QR "zzzzzzzzz" (точно нет совпадений) возвращает null', () {
        final client = findClientByQr('zzzzzzzzz');
        expect(client, isNull);
      });

      test('QR "" (пустая строка) возвращает null', () {
        final client = findClientByQr('');
        expect(client, isNull);
      });
    });

    group('Формат QR-кода', () {
      test('формат "client:<id>" корректно парсится', () {
        expect(findClientByQr('client:1')?.id, 1);
        expect(findClientByQr('client:2')?.id, 2);
        expect(findClientByQr('client:7')?.id, 7);
      });

      test('формат "user:<id>" тоже работает (любой префикс)', () {
        expect(findClientByQr('user:3')?.id, 3);
        expect(findClientByQr('id:5')?.id, 5);
      });

      test('формат без префикса работает', () {
        expect(findClientByQr('1')?.id, 1);
        expect(findClientByQr('7')?.id, 7);
      });
    });
  });
}
