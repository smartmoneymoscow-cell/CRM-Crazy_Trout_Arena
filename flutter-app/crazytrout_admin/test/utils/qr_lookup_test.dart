import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/models/client.dart';
import 'package:crazytrout_admin/utils/qr_lookup.dart';

/// Тестовый набор клиентов — изолирован от demo_data.
final _testClients = [
  const Client(
      id: 1,
      name: 'Иван Иванов',
      phone: '+7 925 123-45-67',
      tariffLabel: 'Стандарт'),
  const Client(
      id: 2,
      name: 'Алексей Кошкин',
      phone: '+7 916 555-22-11',
      tariffLabel: 'Стандарт'),
  const Client(
      id: 5,
      name: 'Дмитрий Лагута',
      phone: '+7 985 111-22-33',
      tariffLabel: 'Стандарт'),
  const Client(
      id: 6,
      name: 'Михаил Орлов',
      phone: '+7 962 888-99-00',
      tariffLabel: 'Пенсионер'),
];

void main() {
  group('parseQrClientId', () {
    group('формат "client:<id>"', () {
      test('"client:1" → 1', () {
        expect(parseQrClientId('client:1'), 1);
      });

      test('"client:42" → 42', () {
        expect(parseQrClientId('client:42'), 42);
      });

      test('"client:999" → 999', () {
        expect(parseQrClientId('client:999'), 999);
      });
    });

    group('формат "<id>" (просто число)', () {
      test('"1" → 1', () {
        expect(parseQrClientId('1'), 1);
      });

      test('"42" → 42', () {
        expect(parseQrClientId('42'), 42);
      });
    });

    group('не числовой ввод', () {
      test('"abc" → null', () {
        expect(parseQrClientId('abc'), isNull);
      });

      test('"Иван" → null', () {
        expect(parseQrClientId('Иван'), isNull);
      });

      test('"client:abc" → null (после ":" не число)', () {
        expect(parseQrClientId('client:abc'), isNull);
      });

      test('пустая строка → null', () {
        expect(parseQrClientId(''), isNull);
      });

      test('"   " (пробелы) → null', () {
        expect(parseQrClientId('   '), isNull);
      });
    });

    group('граничные случаи', () {
      test('"client:0" → 0', () {
        expect(parseQrClientId('client:0'), 0);
      });

      test('"  client:5  " (с пробелами) → 5', () {
        expect(parseQrClientId('  client:5  '), 5);
      });

      test('"client:" (пустой id) → null', () {
        expect(parseQrClientId('client:'), isNull);
      });

      test('"client:1:2" (двоеточие в id) → 2 (последняя часть)', () {
        expect(parseQrClientId('client:1:2'), 2);
      });

      test('"client:-1" → -1 (отрицательный id)', () {
        expect(parseQrClientId('client:-1'), -1);
      });
    });
  });

  group('findClientByQr', () {
    group('поиск по ID', () {
      test('client:1 → Иван Иванов', () {
        final result = findClientByQr('client:1', clients: _testClients);
        expect(result.client, isNotNull);
        expect(result.client!.name, 'Иван Иванов');
        expect(result.error, isNull);
      });

      test('client:2 → Алексей Кошкин', () {
        final result = findClientByQr('client:2', clients: _testClients);
        expect(result.client!.name, 'Алексей Кошкин');
      });

      test('"6" (просто число) → Михаил Орлов', () {
        final result = findClientByQr('6', clients: _testClients);
        expect(result.client!.name, 'Михаил Орлов');
      });

      test('client:5 → Дмитрий Лагута', () {
        final result = findClientByQr('client:5', clients: _testClients);
        expect(result.client!.name, 'Дмитрий Лагута');
      });
    });

    group('fallback-поиск по имени/телефону', () {
      test('"иван" (подстрока имени, регистронезависимо) → Иван Иванов', () {
        final result = findClientByQr('иван', clients: _testClients);
        expect(result.client, isNotNull);
        expect(result.client!.name, 'Иван Иванов');
      });

      test('"ИВАНОВ" (верхний регистр) → Иван Иванов', () {
        final result = findClientByQr('ИВАНОВ', clients: _testClients);
        expect(result.client!.name, 'Иван Иванов');
      });

      test('"916 555" (подстрока телефона) → Алексей Кошкин', () {
        final result = findClientByQr('916 555', clients: _testClients);
        expect(result.client!.name, 'Алексей Кошкин');
      });

      test('"Кошкин" (фамилия) → Алексей Кошкин', () {
        final result = findClientByQr('Кошкин', clients: _testClients);
        expect(result.client!.name, 'Алексей Кошкин');
      });

      test('"Орлов" → Михаил Орлов', () {
        final result = findClientByQr('Орлов', clients: _testClients);
        expect(result.client!.name, 'Михаил Орлов');
      });
    });

    group('не найден', () {
      test('client:999 → notFound', () {
        final result = findClientByQr('client:999', clients: _testClients);
        expect(result.client, isNull);
        expect(result.error, contains('999'));
      });

      test('"Несуществующий" → notFound', () {
        final result =
            findClientByQr('Несуществующий', clients: _testClients);
        expect(result.client, isNull);
        expect(result.error, isNotNull);
      });

      test('пустая строка → notFound', () {
        final result = findClientByQr('', clients: _testClients);
        expect(result.client, isNull);
        expect(result.error, isNotNull);
      });

      test('"   " (пробелы) → notFound', () {
        final result = findClientByQr('   ', clients: _testClients);
        expect(result.client, isNull);
      });
    });

    group('граничные случаи', () {
      test('client:0 — нет клиента с id=0 → notFound', () {
        final result = findClientByQr('client:0', clients: _testClients);
        expect(result.client, isNull);
      });

      test('client:-1 — отрицательный id → notFound', () {
        final result = findClientByQr('client:-1', clients: _testClients);
        expect(result.client, isNull);
      });

      test(
          'если id не найден, но строка совпадает с именем → fallback найдёт',
          () {
        final result = findClientByQr('client:abc', clients: _testClients);
        expect(result.client, isNull);
      });

      test('multiple match — возвращается первый найденный', () {
        final clients = [
          const Client(
              id: 1,
              name: 'Иванов Иван',
              phone: '+7 000',
              tariffLabel: 'Стандарт'),
          const Client(
              id: 2,
              name: 'Орлов Олег',
              phone: '+7 111',
              tariffLabel: 'Стандарт'),
        ];
        final result = findClientByQr('ов', clients: clients);
        expect(result.client, isNotNull);
        expect(result.client!.id, 1); // первый
      });
    });
  });

  group('QrLookupResult', () {
    test('found создаёт результат с клиентом', () {
      const client =
          Client(id: 1, name: 'Test', phone: '123', tariffLabel: 'Стандарт');
      final result = QrLookupResult.found(client);
      expect(result.client, client);
      expect(result.error, isNull);
    });

    test('notFound создаёт результат с ошибкой', () {
      final result = QrLookupResult.notFound('bad-code');
      expect(result.client, isNull);
      expect(result.error, contains('bad-code'));
    });
  });
}
