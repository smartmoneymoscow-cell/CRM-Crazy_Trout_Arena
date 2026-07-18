import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../data/payment_tariff_stats.dart';
import '../utils/format.dart';
import '../theme/app_theme.dart';

// ============================================================================
// PaymentTariffCard — две столбчатые диаграммы на одной строке:
//   Слева: столбчатая — выручка по способам оплаты
//   Справа: столбчатая — количество оплат по тарифам
//
//   ┌─────────────────────┬────────────────────┐
//   │ По способам оплаты  │  По тарифам        │
//   │                     │                    │
//   │  Картой    ████████ │  Стандарт ████████ │
//   │  Наличными ████     │  Гостевой ████     │
//   │  Счёт      ██       │  Пенсион. ██       │
//   │                     │                    │
//   └─────────────────────┴────────────────────┘
// ============================================================================

// ── Цвета приложения ──

// ── Палитра столбцов (оплата) ──
const _barColors = <Color>[
  Color(0xFFE8912B), // оранжевый — Картой
  Color(0xFF4A7C59), // зелёный — Наличными
  Color(0xFF8B6F47), // золотой — Счёт заведения
];

// Градиенты для столбцов
const _barGradients = <List<Color>>[
  [Color(0xFFE8912B), Color(0xFFF2A84D)],
  [Color(0xFF4A7C59), Color(0xFF5FA87A)],
  [Color(0xFF8B6F47), Color(0xFFA88960)],
];

// ── Палитра сегментов (тарифы) ──
const _tarColors = <Color>[
  Color(0xFFE8912B), // оранжевый — Стандарт
  Color(0xFFD4C4A8), // бежевый — Гостевой
  Color(0xFFB8B0A2), // серый — Пенсионер
];

// Градиенты для сегментов тарифов
const _tarGradients = <List<Color>>[
  [Color(0xFFE8912B), Color(0xFFF2A84D)],
  [Color(0xFFD4C4A8), Color(0xFFE0D4BA)],
  [Color(0xFFB8B0A2), Color(0xFFC8C0B4)],
];

class PaymentTariffCard extends StatelessWidget {
  final PaymentTariffStats stats;
  const PaymentTariffCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kPaper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kHairline2, width: 0.5),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Слева: столбцы (оплата) ──
          Expanded(
            child: _PaymentBars(payments: stats.payments),
          ),

          const SizedBox(width: 14),

          // ── Справа: столбцы (тарифы по количеству) ──
          Expanded(
            child: _TariffBars(tariffs: stats.tariffs),
          ),
        ],
      ),
    );
  }
}

// ─── Столбчатая диаграмма способов оплаты ───────────────────────────────────
class _PaymentBars extends StatelessWidget {
  final List<PaymentBreakdown> payments;
  const _PaymentBars({required this.payments});

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) return const SizedBox.shrink();

    final maxAmount = payments.map((e) => e.amount).reduce(math.max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'По способам оплаты',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: kInk,
          ),
        ),
        const SizedBox(height: 14),
        for (int i = 0; i < payments.length; i++) ...[
          _BarRow(
            label: payments[i].label,
            amount: payments[i].amount,
            fraction: maxAmount > 0 ? payments[i].amount / maxAmount : 0,
            color: _barColors[i % _barColors.length],
            gradient: _barGradients[i % _barGradients.length],
          ),
          if (i < payments.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final double amount;
  final double fraction; // 0..1
  final Color color;
  final List<Color> gradient;

  const _BarRow({
    required this.label,
    required this.amount,
    required this.fraction,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Название + сумма
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: kInk,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              money(amount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: kInk,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Столбец
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            height: 10,
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Container(color: kFill),
                  Container(
                    width: constraints.maxWidth * fraction.clamp(0.0, 1.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: LinearGradient(colors: gradient),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Горизонтальные столбцы тарифов (по количеству) ────────────────────────
class _TariffBars extends StatelessWidget {
  final List<TariffBreakdown> tariffs;
  const _TariffBars({required this.tariffs});

  @override
  Widget build(BuildContext context) {
    if (tariffs.isEmpty) return const SizedBox.shrink();

    final totalCount = tariffs.fold<int>(0, (s, e) => s + e.count);
    final maxCount = tariffs.map((e) => e.count).reduce(math.max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'По тарифам (в шт.)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: kInk,
          ),
        ),
        const SizedBox(height: 14),
        for (int i = 0; i < tariffs.length; i++) ...[
          _TariffBarRow(
            label: tariffs[i].label,
            count: tariffs[i].count,
            totalCount: totalCount,
            fraction: maxCount > 0 ? tariffs[i].count / maxCount : 0,
            color: _tarColors[i % _tarColors.length],
            gradient: _tarGradients[i % _tarGradients.length],
          ),
          if (i < tariffs.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _TariffBarRow extends StatelessWidget {
  final String label;
  final int count;
  final int totalCount;
  final double fraction;
  final Color color;
  final List<Color> gradient;

  const _TariffBarRow({
    required this.label,
    required this.count,
    required this.totalCount,
    required this.fraction,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final pct = totalCount > 0 ? (count / totalCount * 100).round() : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: kInk,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count ($pct%)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: kInk,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            height: 10,
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Container(color: kFill),
                  Container(
                    width: constraints.maxWidth * fraction.clamp(0.0, 1.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: LinearGradient(colors: gradient),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}


