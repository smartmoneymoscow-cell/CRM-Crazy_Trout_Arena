import 'client.dart';

enum PaymentMethod { cash, card, houseAccount }

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Наличными';
      case PaymentMethod.card:
        return 'Картой';
      case PaymentMethod.houseAccount:
        return 'Счет заведения';
    }
  }
}

/// Система налогообложения (54-ФЗ, ст. 4.7).
enum TaxSystem {
  osn('ОСН'),
  usnIncome('УСН доходы'),
  usnIncomeMinusExpense('УСН доходы минус расходы'),
  esn('ЕСН'),
  patent('Патент');

  final String label;
  const TaxSystem(this.label);
}

/// Признак расчёта (54-ФЗ, ст. 4.7).
enum OperationType {
  income('Приход'),
  incomeReturn('Возврат прихода'),
  expense('Расход'),
  expenseReturn('Возврат расхода');

  final String label;
  const OperationType(this.label);
}

/// Строка улова в чеке.
class ReceiptRow {
  final String name;
  final double weight;
  final double price;
  final double sum;

  const ReceiptRow({
    required this.name,
    required this.weight,
    required this.price,
    required this.sum,
  });
}

/// Кассовый чек с реквизитами по 54-ФЗ ст. 4.7.
class Receipt {
  // ─── Основное ───
  final int number;
  final DateTime date;
  final Client? client;
  final bool isGuest;
  final String tariffLabel;
  final int tariffPrice;
  final List<ReceiptRow> rows;
  final double total;
  final PaymentMethod payment;
  final bool fiscal;
  final String? fiscalDoc;

  // ─── Фискальные реквизиты (54-ФЗ) ───
  final String sellerName;
  final String sellerINN;
  final String sellerAddress;
  final String? sellerEmail;
  final TaxSystem taxSystem;
  final OperationType operationType;
  final int shiftNumber;
  final String kktNumber;
  final String fnNumber;
  final int fdNumber;
  final String fpd;
  final double ndsRate;
  final double ndsSum;
  final String? buyerEmail;

  const Receipt({
    required this.number,
    required this.date,
    required this.client,
    required this.isGuest,
    required this.tariffLabel,
    required this.tariffPrice,
    required this.rows,
    required this.total,
    required this.payment,
    required this.fiscal,
    this.fiscalDoc,
    this.sellerName = 'ИП Сидоров А.В.',
    this.sellerINN = '770123456789',
    this.sellerAddress = 'г. Москва, ул. Рыбацкая, д. 12',
    this.sellerEmail = 'info@crazytrout.ru',
    this.taxSystem = TaxSystem.usnIncome,
    this.operationType = OperationType.income,
    this.shiftNumber = 1,
    this.kktNumber = '0001234567001234',
    this.fnNumber = '9999078900001234',
    this.fdNumber = 0,
    this.fpd = '0000000000',
    this.ndsRate = 0,
    this.ndsSum = 0,
    this.buyerEmail,
  });

  String get clientLine => isGuest
      ? 'Гость (без анкеты)'
      : (client != null ? '${client!.name} · ${client!.phone}' : '—');
}
