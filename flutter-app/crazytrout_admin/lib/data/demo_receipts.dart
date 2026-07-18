import '../models/client.dart';
import '../models/receipt_history.dart';
import 'demo_data.dart';

/// Демо-история чеков для экрана «Чеки».
/// В реальном приложении заменяется на выборку из backend / локальной БД.
final List<ReceiptHistoryItem> kDemoReceipts = _buildDemo();

Client? _c(int id) {
  for (final c in kDemoClients) {
    if (c.id == id) return c;
  }
  return null;
}

List<ReceiptHistoryItem> _buildDemo() {
  final now = DateTime.now();
  DateTime d(int daysAgo, int h, int m) =>
      DateTime(now.year, now.month, now.day, h, m)
          .subtract(Duration(days: daysAgo));

  int seq = 1247;
  int nextN() => seq++;

  return [
    // Сегодня
    ReceiptHistoryItem(
      number: nextN(), date: d(0, 14, 22), client: _c(1), isGuest: false,
      tariffLabel: 'Стандарт', tariffPrice: 750,
      rows: const [
        ReceiptHistoryRow(name: 'Осётр', weight: 2.4, price: 1890, sum: 4536),
      ],
      total: 5286, fiscal: true, paymentLabel: 'Картой', fiscalDoc: '#48291',
    ),
    ReceiptHistoryItem(
      number: nextN(), date: d(0, 11, 5), client: _c(2), isGuest: false,
      tariffLabel: 'Стандарт', tariffPrice: 750,
      rows: const [
        ReceiptHistoryRow(name: 'Карп', weight: 1.8, price: 590, sum: 1062),
      ],
      total: 1812, fiscal: false, paymentLabel: 'Наличными',
    ),
    ReceiptHistoryItem(
      number: nextN(), date: d(0, 9, 40), client: null, isGuest: true,
      tariffLabel: 'Гостевой', tariffPrice: 500,
      rows: const [], total: 500, fiscal: true, paymentLabel: 'Картой',
      fiscalDoc: '#48293',
    ),
    // Вчера / эта неделя
    ReceiptHistoryItem(
      number: nextN(), date: d(1, 17, 10), client: _c(3), isGuest: false,
      tariffLabel: 'Стандарт', tariffPrice: 750,
      rows: const [
        ReceiptHistoryRow(name: 'Форель', weight: 1.2, price: 1200, sum: 1440),
      ],
      total: 2190, fiscal: true, paymentLabel: 'Картой', fiscalDoc: '#48287',
    ),
    ReceiptHistoryItem(
      number: nextN(), date: d(3, 12, 30), client: _c(5), isGuest: false,
      tariffLabel: 'Стандарт', tariffPrice: 750,
      rows: const [
        ReceiptHistoryRow(name: 'Осётр', weight: 4.9, price: 1890, sum: 9261),
      ],
      total: 10011, fiscal: true, paymentLabel: 'Картой', fiscalDoc: '#48260',
    ),
    // Этот месяц
    ReceiptHistoryItem(
      number: nextN(), date: d(12, 15, 0), client: _c(6), isGuest: false,
      tariffLabel: 'Пенсионер', tariffPrice: 0,
      rows: const [
        ReceiptHistoryRow(name: 'Карп', weight: 0.9, price: 590, sum: 531),
      ],
      total: 531, fiscal: false, paymentLabel: 'Наличными',
    ),
    ReceiptHistoryItem(
      number: nextN(), date: d(20, 18, 45), client: _c(7), isGuest: false,
      tariffLabel: 'Стандарт', tariffPrice: 750,
      rows: const [
        ReceiptHistoryRow(name: 'Амур', weight: 2.1, price: 750, sum: 1575),
      ],
      total: 2325, fiscal: true, paymentLabel: 'Картой', fiscalDoc: '#48120',
    ),
    // Прошлый квартал
    ReceiptHistoryItem(
      number: nextN(), date: d(48, 10, 15), client: _c(8), isGuest: false,
      tariffLabel: 'Стандарт', tariffPrice: 750,
      rows: const [
        ReceiptHistoryRow(name: 'Линь', weight: 1.4, price: 690, sum: 966),
      ],
      total: 1716, fiscal: true, paymentLabel: 'Картой', fiscalDoc: '#47950',
    ),
    ReceiptHistoryItem(
      number: nextN(), date: d(70, 13, 0), client: _c(100), isGuest: false,
      tariffLabel: 'Стандарт', tariffPrice: 750,
      rows: const [
        ReceiptHistoryRow(name: 'Осётр', weight: 3.2, price: 1890, sum: 6048),
      ],
      total: 6798, fiscal: false, paymentLabel: 'Наличными',
    ),
    // Счёт заведения
    ReceiptHistoryItem(
      number: nextN(), date: d(2, 16, 30), client: _c(3), isGuest: false,
      tariffLabel: 'Стандарт', tariffPrice: 750,
      rows: const [
        ReceiptHistoryRow(name: 'Карп', weight: 2.5, price: 590, sum: 1475),
      ],
      total: 2225, fiscal: true, paymentLabel: 'Счет заведения', fiscalDoc: '#48300',
    ),
    ReceiptHistoryItem(
      number: nextN(), date: d(5, 10, 0), client: _c(6), isGuest: false,
      tariffLabel: 'Стандарт', tariffPrice: 750,
      rows: const [
        ReceiptHistoryRow(name: 'Форель', weight: 1.8, price: 1200, sum: 2160),
      ],
      total: 2910, fiscal: true, paymentLabel: 'Счет заведения', fiscalDoc: '#48295',
    ),
    ReceiptHistoryItem(
      number: nextN(), date: d(15, 14, 20), client: _c(8), isGuest: false,
      tariffLabel: 'Стандарт', tariffPrice: 750,
      rows: const [
        ReceiptHistoryRow(name: 'Амур', weight: 1.5, price: 750, sum: 1125),
      ],
      total: 1875, fiscal: false, paymentLabel: 'Счет заведения',
    ),
    // Пенсионер + Картой + С ФН (для покрытия комбинаций фильтров)
    ReceiptHistoryItem(
      number: nextN(), date: d(4, 11, 15), client: _c(6), isGuest: false,
      tariffLabel: 'Пенсионер', tariffPrice: 0,
      rows: const [
        ReceiptHistoryRow(name: 'Линь', weight: 1.1, price: 690, sum: 759),
      ],
      total: 759, fiscal: true, paymentLabel: 'Картой', fiscalDoc: '#48270',
    ),
    // Гостевой + Наличными (для покрытия комбинаций фильтров)
    ReceiptHistoryItem(
      number: nextN(), date: d(6, 16, 0), client: null, isGuest: true,
      tariffLabel: 'Гостевой', tariffPrice: 500,
      rows: const [
        ReceiptHistoryRow(name: 'Карп', weight: 0.8, price: 590, sum: 472),
      ],
      total: 972, fiscal: true, paymentLabel: 'Наличными', fiscalDoc: '#48265',
    ),
    // Нина Крюкова (id=4): Пенсионер + Картой + С ФН, Неделя (Первый раз)
    ReceiptHistoryItem(
      number: nextN(), date: d(4, 11, 15), client: _c(4), isGuest: false,
      tariffLabel: 'Пенсионер', tariffPrice: 0,
      rows: const [
        ReceiptHistoryRow(name: 'Линь', weight: 1.1, price: 690, sum: 759),
      ],
      total: 759, fiscal: true, paymentLabel: 'Картой', fiscalDoc: '#48270',
    ),
    // Нина Крюкова: Пенсионер + Счет заведения + С ФН, Квартал (Первый раз)
    ReceiptHistoryItem(
      number: nextN(), date: d(25, 14, 30), client: _c(4), isGuest: false,
      tariffLabel: 'Пенсионер', tariffPrice: 0,
      rows: const [
        ReceiptHistoryRow(name: 'Карп', weight: 1.3, price: 590, sum: 767),
      ],
      total: 767, fiscal: true, paymentLabel: 'Счет заведения', fiscalDoc: '#48100',
    ),
    // Нина Крюкова: Пенсионер + Наличными + Без ФН (Первый раз)
    ReceiptHistoryItem(
      number: nextN(), date: d(18, 9, 0), client: _c(4), isGuest: false,
      tariffLabel: 'Пенсионер', tariffPrice: 0,
      rows: const [
        ReceiptHistoryRow(name: 'Форель', weight: 0.7, price: 1200, sum: 840),
      ],
      total: 840, fiscal: false, paymentLabel: 'Наличными',
    ),
    // Иванов: Стандарт + Картой + Без ФН, Неделя
    ReceiptHistoryItem(
      number: nextN(), date: d(3, 10, 45), client: _c(1), isGuest: false,
      tariffLabel: 'Стандарт', tariffPrice: 750,
      rows: const [
        ReceiptHistoryRow(name: 'Амур', weight: 1.6, price: 750, sum: 1200),
      ],
      total: 1950, fiscal: false, paymentLabel: 'Картой',
    ),
    // Гость: Гостевой + Счет заведения + С ФН, Месяц
    ReceiptHistoryItem(
      number: nextN(), date: d(22, 15, 20), client: null, isGuest: true,
      tariffLabel: 'Гостевой', tariffPrice: 500,
      rows: const [
        ReceiptHistoryRow(name: 'Линь', weight: 0.5, price: 690, sum: 345),
      ],
      total: 845, fiscal: true, paymentLabel: 'Счет заведения', fiscalDoc: '#48110',
    ),
    // Гость: Гостевой + Картой + Без ФН
    ReceiptHistoryItem(
      number: nextN(), date: d(35, 13, 0), client: null, isGuest: true,
      tariffLabel: 'Гостевой', tariffPrice: 500,
      rows: const [],
      total: 500, fiscal: false, paymentLabel: 'Картой',
    ),
    // Джереми: Стандарт + Картой + С ФН, Сегодня (Первый раз)
    ReceiptHistoryItem(
      number: nextN(), date: d(0, 10, 30), client: _c(100), isGuest: false,
      tariffLabel: 'Стандарт', tariffPrice: 750,
      rows: const [
        ReceiptHistoryRow(name: 'Осётр', weight: 1.5, price: 1890, sum: 2835),
      ],
      total: 3585, fiscal: true, paymentLabel: 'Картой', fiscalDoc: '#48310',
    ),
    // Джереми: Стандарт + Счет заведения + С ФН, Неделя (Первый раз)
    ReceiptHistoryItem(
      number: nextN(), date: d(5, 14, 0), client: _c(100), isGuest: false,
      tariffLabel: 'Стандарт', tariffPrice: 750,
      rows: const [
        ReceiptHistoryRow(name: 'Карп', weight: 2.0, price: 590, sum: 1180),
      ],
      total: 1930, fiscal: true, paymentLabel: 'Счет заведения', fiscalDoc: '#48290',
    ),
    // Крюкова: Пенсионер + Наличными + С ФН, Сегодня (Первый раз)
    ReceiptHistoryItem(
      number: nextN(), date: d(0, 13, 0), client: _c(4), isGuest: false,
      tariffLabel: 'Пенсионер', tariffPrice: 0,
      rows: const [
        ReceiptHistoryRow(name: 'Форель', weight: 0.9, price: 1200, sum: 1080),
      ],
      total: 1080, fiscal: true, paymentLabel: 'Наличными', fiscalDoc: '#48315',
    ),
    // Гость: Гостевой + Счет заведения + Без ФН
    ReceiptHistoryItem(
      number: nextN(), date: d(40, 11, 0), client: null, isGuest: true,
      tariffLabel: 'Гостевой', tariffPrice: 500,
      rows: const [
        ReceiptHistoryRow(name: 'Амур', weight: 1.0, price: 750, sum: 750),
      ],
      total: 1250, fiscal: false, paymentLabel: 'Счет заведения',
    ),
    // Кошкин: Стандарт + Наличными + С ФН
    ReceiptHistoryItem(
      number: nextN(), date: d(8, 15, 30), client: _c(2), isGuest: false,
      tariffLabel: 'Стандарт', tariffPrice: 750,
      rows: const [
        ReceiptHistoryRow(name: 'Форель', weight: 1.4, price: 1200, sum: 1680),
      ],
      total: 2430, fiscal: true, paymentLabel: 'Наличными', fiscalDoc: '#48250',
    ),
    // Сегодня: Стандарт + Счет заведения + С ФН
    ReceiptHistoryItem(
      number: nextN(), date: d(0, 16, 0), client: _c(3), isGuest: false,
      tariffLabel: 'Стандарт', tariffPrice: 750,
      rows: const [
        ReceiptHistoryRow(name: 'Карп', weight: 2.2, price: 590, sum: 1298),
      ],
      total: 2048, fiscal: true, paymentLabel: 'Счет заведения', fiscalDoc: '#48320',
    ),
    // Сегодня: Гостевой + Наличными + С ФН
    ReceiptHistoryItem(
      number: nextN(), date: d(0, 12, 0), client: null, isGuest: true,
      tariffLabel: 'Гостевой', tariffPrice: 500,
      rows: const [
        ReceiptHistoryRow(name: 'Линь', weight: 0.6, price: 690, sum: 414),
      ],
      total: 914, fiscal: true, paymentLabel: 'Наличными', fiscalDoc: '#48318',
    ),
    // Сегодня: Пенсионер + Картой + С ФН
    ReceiptHistoryItem(
      number: nextN(), date: d(0, 15, 30), client: _c(4), isGuest: false,
      tariffLabel: 'Пенсионер', tariffPrice: 0,
      rows: const [
        ReceiptHistoryRow(name: 'Карп', weight: 1.0, price: 590, sum: 590),
      ],
      total: 590, fiscal: true, paymentLabel: 'Картой', fiscalDoc: '#48322',
    ),
  ]..sort((a, b) => b.date.compareTo(a.date));
}
