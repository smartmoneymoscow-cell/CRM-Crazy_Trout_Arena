import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/models/tariff.dart';

void main() {
  group('Tariff — модель тарифа', () {
    test('создание с корректными полями', () {
      const t = Tariff(id: 'standard', label: 'Стандарт', price: 750);
      expect(t.id, 'standard');
      expect(t.label, 'Стандарт');
      expect(t.price, 750);
    });

    test('const-конструктор работает', () {
      const t1 = Tariff(id: 'guest', label: 'Гостевой', price: 500);
      const t2 = Tariff(id: 'guest', label: 'Гостевой', price: 500);
      expect(t1, equals(t2));
    });

    test('нулевая цена (Пенсионер)', () {
      const t = Tariff(id: 'pensioner', label: 'Пенсионер', price: 0);
      expect(t.price, 0);
    });

    test('id и label не связаны жёстко', () {
      const t = Tariff(id: 'custom', label: 'Произвольный', price: 999);
      expect(t.id, isNot(equals(t.label)));
    });
  });
}
