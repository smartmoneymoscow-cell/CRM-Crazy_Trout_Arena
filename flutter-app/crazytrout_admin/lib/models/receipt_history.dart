import 'client.dart';

/// Одна позиция в чеке из истории (лёгкая версия ReceiptRow —
/// используется только для отображения на экране «Чеки»).
class ReceiptHistoryRow {
  final String name;
  final double weight;
  final double price;
  final double sum;

  const ReceiptHistoryRow({
    required this.name,
    required this.weight,
    required this.price,
    required this.sum,
  });
}

/// Один чек в истории (экран «Чеки»). Сознательно отделён от Receipt из
/// receipt_screen.dart, чтобы можно было хранить готовые демо-данные без
/// пересборки PaymentMethod и списка ReceiptRow.
class ReceiptHistoryItem {
  final int number;
  final DateTime date;
  final Client? client;
  final bool isGuest;
  final String tariffLabel;
  final int tariffPrice;
  final List<ReceiptHistoryRow> rows;
  final double total;
  final bool fiscal;
  final String paymentLabel; // «Наличными» / «Картой»
  final String? fiscalDoc;

  const ReceiptHistoryItem({
    required this.number,
    required this.date,
    required this.client,
    required this.isGuest,
    required this.tariffLabel,
    required this.tariffPrice,
    required this.rows,
    required this.total,
    required this.fiscal,
    required this.paymentLabel,
    this.fiscalDoc,
  });

  String get displayName => isGuest
      ? 'Гость (без анкеты)'
      : (client?.name ?? 'Без клиента');
}
