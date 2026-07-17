// ============================================================================
// payment_tariff_stats.dart — Агрегация выручки по способам оплаты и тарифам.
//
// Источник: demo_receipts.dart. В production заменяется на backend.
// ============================================================================

import 'package:flutter/material.dart';
import '../data/demo_receipts.dart';

class PaymentBreakdown {
  final String label;
  final double amount;
  const PaymentBreakdown({required this.label, required this.amount});
}

class TariffBreakdown {
  final String label;
  final double amount;
  final int count;
  const TariffBreakdown({required this.label, required this.amount, required this.count});
}

class PaymentTariffStats {
  final List<PaymentBreakdown> payments;
  final List<TariffBreakdown> tariffs;
  final double totalRevenue;

  const PaymentTariffStats({
    required this.payments,
    required this.tariffs,
    required this.totalRevenue,
  });
}

/// Строит статистику оплат и тарифов из демо-чеков.
/// [dateRange] — если задан, фильтрует чеки по дате.
PaymentTariffStats buildPaymentTariffStats({DateTimeRange? dateRange}) {
  final payMap = <String, double>{};
  final tarMap = <String, double>{};
  final tarCount = <String, int>{};

  for (final r in kDemoReceipts) {
    // Фильтр по дате
    if (dateRange != null) {
      final d = DateTime(r.date.year, r.date.month, r.date.day);
      final s = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
      final e = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day);
      if (d.isBefore(s) || d.isAfter(e)) continue;
    }

    // Способ оплаты
    payMap[r.paymentLabel] = (payMap[r.paymentLabel] ?? 0) + r.total;

    // Тариф
    tarMap[r.tariffLabel] = (tarMap[r.tariffLabel] ?? 0) + r.tariffPrice;
    tarCount[r.tariffLabel] = (tarCount[r.tariffLabel] ?? 0) + 1;
  }

  final payments = payMap.entries
      .map((e) => PaymentBreakdown(label: e.key, amount: e.value))
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));

  final tariffs = tarMap.entries
      .map((e) => TariffBreakdown(
            label: e.key,
            amount: e.value,
            count: tarCount[e.key] ?? 0,
          ))
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));

  final total = payments.fold<double>(0, (s, e) => s + e.amount);

  return PaymentTariffStats(
    payments: payments,
    tariffs: tariffs,
    totalRevenue: total,
  );
}
