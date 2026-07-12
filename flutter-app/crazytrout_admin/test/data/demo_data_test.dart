import 'package:flutter_test/flutter_test.dart';
import 'package:crazytrout_admin/data/demo_data.dart';
import 'package:crazytrout_admin/models/tariff.dart';

void main() {
  group('DemoData — консистентность данных', () {
    group('Тарифы (kTariffs)', () {
      test('ровно 3 тарифа', () {
        expect(kTariffs.length, 3);
      });

      test('Стандарт = 750₽', () {
        final t = kTariffs.firstWhere((t) => t.id == 'standard');
        expect(t.label, 'Стандарт');
        expect(t.price, 750);
      });

      test('Гостевой = 500₽', () {
        final t = kTariffs.firstWhere((t) => t.id == 'guest');
        expect(t.label, 'Гостевой');
        expect(t.price, 500);
      });

      test('Пенсионер = 0₽', () {
        final t = kTariffs.firstWhere((t) => t.id == 'pensioner');
        expect(t.label, 'Пенсионер');
        expect(t.price, 0);
      });

      test('все id уникальны', () {
        final ids = kTariffs.map((t) => t.id).toSet();
        expect(ids.length, kTariffs.length);
      });
    });

    group('Породы рыб (kSpecies)', () {
      test('ровно 5 пород', () {
        expect(kSpecies.length, 5);
      });

      test('все названия непустые', () {
        for (final s in kSpecies) {
          expect(s.trim(), isNotEmpty);
        }
      });

      test('все названия уникальны', () {
        final unique = kSpecies.toSet();
        expect(unique.length, kSpecies.length);
      });
    });

    group('Цены за кг (kSpeciesPrice)', () {
      test('каждая порода имеет цену', () {
        for (final species in kSpecies) {
          expect(kSpeciesPrice.containsKey(species), isTrue,
              reason: 'Нет цены для $species');
        }
      });

      test('все цены положительные', () {
        for (final entry in kSpeciesPrice.entries) {
          expect(entry.value, greaterThan(0), reason: '${entry.key} имеет цену ${entry.value}');
        }
      });

      test('Осётр — самая дорогая рыба', () {
        final maxPrice = kSpeciesPrice.values.reduce((a, b) => a > b ? a : b);
        expect(kSpeciesPrice['Осётр'], maxPrice);
      });

      test('каждая порода из kSpecies есть в kSpeciesPrice', () {
        expect(kSpeciesPrice.length, kSpecies.length);
      });
    });

    group('Демо-клиенты (kDemoClients)', () {
      test('ровно 8 клиентов (7 реальных + 1 мок)', () {
        expect(kDemoClients.length, 8);
      });

      test('все id уникальны', () {
        final ids = kDemoClients.map((c) => c.id).toSet();
        expect(ids.length, kDemoClients.length);
      });

      test('все имена непустые', () {
        for (final c in kDemoClients) {
          expect(c.name.trim(), isNotEmpty, reason: 'Клиент id=${c.id} без имени');
        }
      });

      test('все телефоны непустые', () {
        for (final c in kDemoClients) {
          expect(c.phone.trim(), isNotEmpty, reason: 'Клиент ${c.name} без телефона');
        }
      });

      test('tariffLabel каждого клиента — валидный тариф', () {
        final tariffLabels = kTariffs.map((t) => t.label).toSet();
        for (final c in kDemoClients) {
          expect(tariffLabels.contains(c.tariffLabel), isTrue,
              reason: 'Клиент ${c.name} имеет невалидный тариф ${c.tariffLabel}');
        }
      });

      test('Михаил Орлов — Пенсионер', () {
        final mikhail = kDemoClients.firstWhere((c) => c.id == 6);
        expect(mikhail.tariffLabel, 'Пенсионер');
      });
    });
  });
}
