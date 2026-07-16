import 'package:flutter/material.dart';

import '../data/demo_finance_stats.dart';
import '../utils/format.dart';

// ============================================================================
// FinanceDashboardCard — карточка «Выручка / Маржинальная прибыль /
// Переменные расходы» со спарклайном, портирована из dashboard_2.html
// на нативные виджеты Flutter (без WebView).
//
// Разметка HTML-макета:
//   ┌───────────────────────┬──┬───────────────┐
//   │  Выручка (тёмная,     │  │ Маржинальная  │
//   │  большая) + спарклайн │)( │ прибыль       │
//   │                       │  ├───────────────┤
//   │                       │  │ Переменные    │
//   │                       │  │ расходы       │
//   └───────────────────────┴──┴───────────────┘
// ============================================================================

const _cream = Color(0xFFF3EFE7);
const _orange = Color(0xFFE08A35);
const _textLight = Color(0xFFEFE9DF);
const _statLight = Color(0xFFF8F5EF);
const _delta = Color(0xFF4F9D75);
const _deltaLabel = Color(0xFF8B8579);

class FinanceDashboardCard extends StatelessWidget {
  final FinanceStats stats;

  const FinanceDashboardCard({super.key, this.stats = kDemoFinanceStats});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: IntrinsicHeight(
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Левая карточка: выручка + спарклайн ──
              Expanded(
                flex: 5,
                child: _RevenueCard(stats: stats),
              ),

              // ── «Скоба»-разделитель ──
              const SizedBox(
                width: 22,
                child: CustomPaint(painter: _BracePainter()),
              ),

              // ── Правая колонка: 2 карточки статистики ──
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Expanded(
                      child: _StatCard(
                        labelMain: 'Маржинальная',
                        labelSub: 'прибыль',
                        value: money(stats.marginProfit),
                        pctLabel:
                            '${_fmtPct(stats.marginPct)}% маржинальность',
                        dark: false,
                        progress: stats.marginPct / 100,
                        progressColor: const [
                          Color(0xFF2F8F5B),
                          Color(0xFF4CAF7D),
                        ],
                        radius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                      ),
                    ),
                    Expanded(
                      child: _StatCard(
                        labelMain: 'Переменные',
                        labelSub: 'расходы',
                        value: money(stats.variableExpenses),
                        pctLabel:
                            '${_fmtPct(stats.expensesPct)}% от выручки',
                        dark: true,
                        progress: stats.expensesPct / 100,
                        progressColor: const [
                          Color(0xFFC0392B),
                          Color(0xFFE15C4D),
                        ],
                        radius: const BorderRadius.vertical(
                            bottom: Radius.circular(16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}

String _fmtPct(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

// ─── Левая тёмная карточка «Выручка» ────────────────────────────────────────
class _RevenueCard extends StatelessWidget {
  final FinanceStats stats;
  const _RevenueCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isUp = stats.revenueDeltaPct >= 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment(-0.6, -1),
          end: Alignment(0.6, 1),
          colors: [Color(0xFF1D1B18), Color(0xFF131211)],
          stops: [0, 0.7],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Выручка',
                style: TextStyle(
                  color: _textLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                money(stats.revenue),
                style: const TextStyle(
                  color: _orange,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${isUp ? '+' : ''}${_fmtPct(stats.revenueDeltaPct)}%',
                style: TextStyle(
                  color: isUp ? _delta : const Color(0xFFE15C4D),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'к прошлому периоду',
                style: TextStyle(color: _deltaLabel, fontSize: 10.5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            width: double.infinity,
            child: CustomPaint(
              painter: _SparklinePainter(stats.sparkline),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Правая карточка статистики (маржа / расходы) ───────────────────────────
class _StatCard extends StatelessWidget {
  final String labelMain;
  final String labelSub;
  final String value;
  final String pctLabel;
  final bool dark;
  final double progress;
  final List<Color> progressColor;
  final BorderRadius radius;

  const _StatCard({
    required this.labelMain,
    required this.labelSub,
    required this.value,
    required this.pctLabel,
    required this.dark,
    required this.progress,
    required this.progressColor,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = dark ? const Color(0xFFF0D9D3) : const Color(0xFF7A7266);
    final subColor = dark ? const Color(0xFFA97B71) : const Color(0xFFB7B0A2);
    final valueColor = dark ? const Color(0xFFE2604C) : const Color(0xFF1C1A17);
    final pctColor = dark ? const Color(0xFFB98077) : const Color(0xFFA49C8D);
    final trackColor = dark ? const Color(0xFF4A2B26) : const Color(0xFFE1DCCF);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        borderRadius: radius,
        color: dark ? null : _statLight,
        gradient: dark
            ? const LinearGradient(
                begin: Alignment(-0.6, -1),
                end: Alignment(0.6, 1),
                colors: [Color(0xFF2C1613), Color(0xFF170B0A)],
                stops: [0, 0.7],
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(labelMain,
                  style: TextStyle(
                      color: labelColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
              Text(labelSub,
                  style: TextStyle(
                      color: subColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      color: valueColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2)),
              const SizedBox(height: 4),
              Text(pctLabel,
                  style: TextStyle(
                      color: pctColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 6,
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Container(color: trackColor),
                    Container(
                      width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: progressColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Спарклайн выручки (аналог <svg class="sparkline"> из HTML) ────────────
class _SparklinePainter extends CustomPainter {
  final List<double> points; // значения 0..1

  _SparklinePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = _orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final n = points.length;
    final dx = size.width / (n - 1);
    Offset toOffset(int i) => Offset(
          i * dx,
          size.height - points[i] * size.height,
        );

    final path = Path()..moveTo(toOffset(0).dx, toOffset(0).dy);
    for (int i = 0; i < n - 1; i++) {
      final p0 = toOffset(i);
      final p1 = toOffset(i + 1);
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      if (i == n - 2) path.lineTo(p1.dx, p1.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.points != points;
}

// ─── Декоративная «скоба» между колонками (аналог .brace-col из HTML) ──────
class _BracePainter extends CustomPainter {
  const _BracePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC9BFA9)
      ..style = PaintingStyle.fill;

    // Пропорции из HTML SVG (viewBox 0 0 28 400):
    //   внешний край: x от 28 → 10.75 (в центре) → 28
    //   внутренний край: x от 28 → 17 (в центре) → 28
    //   кончик: x ≈ -0.23, y ≈ 197/400 ≈ 0.493
    final w = size.width;
    final h = size.height;

    // Единый замкнутый путь:
    // 1) Внешний контур сверху вниз
    // 2) Внутренний контур снизу вверх
    final path = Path()
      // Начало: верхний правый угол внешнего контура
      ..moveTo(w, 0)
      // Внешний контур вниз к кончику
      ..cubicTo(
        w * 0.385, h * 0.075,
        w * 0.385, h * 0.425,
        -w * 0.008, h * 0.493,
      )
      // Внешний контур от кончика вниз
      ..cubicTo(
        w * 0.385, h * 0.575,
        w * 0.385, h * 0.925,
        w, h,
      )
      // Переход к внутреннему контру снизу
      // Внутренний контур снизу вверх к кончику
      ..cubicTo(
        w * 0.555, h * 0.953,
        w * 0.555, h * 0.548,
        w * 0.008, h * 0.493,
      )
      // Внутренний контур от кончика вверх
      ..cubicTo(
        w * 0.555, h * 0.453,
        w * 0.555, h * 0.048,
        w, h * 0.002,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BracePainter oldDelegate) => false;
}
