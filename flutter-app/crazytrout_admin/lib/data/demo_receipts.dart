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
  ]..sort((a, b) => b.date.compareTo(a.date));
}
