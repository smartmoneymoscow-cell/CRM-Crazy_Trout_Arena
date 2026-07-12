import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/models/client.dart';

void main() {
  group('Client — модель клиента', () {
    group('initials (инициалы)', () {
      test('Иван Иванов → ИИ', () {
        final client = Client(id: 1, name: 'Иван Иванов', phone: '+7 925 123-45-67', tariffLabel: 'Стандарт');
        expect(client.initials, 'ИИ');
      });

      test('Анна Морозова → АМ', () {
        final client = Client(id: 4, name: 'Анна Морозова', phone: '+7 925 333-00-99', tariffLabel: 'Стандарт');
        expect(client.initials, 'АМ');
      });

      test('Олег → О', () {
        final client = Client(id: 7, name: 'Олег', phone: '+7 905 222-77-66', tariffLabel: 'Стандарт');
        expect(client.initials, 'О');
      });

      test('пустое имя → пустая строка', () {
        final client = Client(id: 0, name: '', phone: '', tariffLabel: '');
        expect(client.initials, '');
      });
    });

    group('avatarAsset (аватар)', () {
      test('клиент с аватаром', () {
        final client = Client(
          id: 1,
          name: 'Иван Иванов',
          phone: '+7 925 123-45-67',
          tariffLabel: 'Стандарт',
          avatarAsset: 'assets/avatars/avatar_1.jpeg',
        );
        expect(client.avatarAsset, isNotNull);
        expect(client.avatarAsset, contains('avatar_1'));
      });

      test('клиент без аватара', () {
        final client = Client(id: 5, name: 'Дмитрий Лагута', phone: '+7 985 111-22-33', tariffLabel: 'Стандарт');
        expect(client.avatarAsset, isNull);
      });
    });
  });
}
