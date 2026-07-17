import 'dart:math' as math;

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
const _statGreen = Color(0xFFF0F7F2);
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
                flex: 4,
                child: _RevenueCard(stats: stats),
              ),

              // ── «Скоба»-разделитель ──
              SizedBox(
                width: 22,
                child: ClipRect(
                  child: CustomPaint(painter: const _BracePainter()),
                ),
              ),

              // ── Правая колонка: 2 карточки статистики ──
              Expanded(
                flex: 5,
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment(-0.6, -1),
          end: Alignment(0.6, 1),
          colors: [Color(0xFF1D1B18), Color(0xFF131211)],
          stops: [0, 0.7],
        ),
      ),
      child: Stack(
        children: [
          // Декоративное свечение в углу — как на референсе (pond-map-preview_.tsx)
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_orange.withOpacity(0.20), _orange.withOpacity(0.0)],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
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
                  child: ClipRect(
                    child: CustomPaint(
                      painter: _SparklinePainter(stats.sparkline),
                    ),
                  ),
                ),
              ],
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
    final valueColor = dark ? const Color(0xFFE2604C) : const Color(0xFF2E7D4F);
    final pctColor = dark ? const Color(0xFFB98077) : const Color(0xFFA49C8D);
    final trackColor = dark ? const Color(0xFF4A2B26) : const Color(0xFFE1DCCF);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        borderRadius: radius,
        color: dark ? null : _statGreen,
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
//
// В отличие от прежней версии (две независимые кривые Безье outer/inner),
// здесь скоба строится из ЕДИНОЙ центральной линии + функции сужения
// ширины w(t) = wMin + (wMax-wMin)·sin²(2πt), где t — доля пройденного
// пути от 0 до 1. У этой функции три минимума (тонко): верх, кончик
// посередине, низ — и два максимума (утолщение) на «плечах» между ними —
// именно так устроена скоба на референсном макете (dashboard_2.html).
// Пропорции опорных точек — из исходного SVG (viewBox 0 0 28 400),
// масштабируются под фактический размер виджета динамически, поэтому
// угол острия не «плывёт» при разной высоте карточки.
class _BracePainter extends CustomPainter {
  const _BracePainter();

  static const _color = Color(0xFFC9BFA9);
  static const _wMin = 0.6;
  static const _wMax = 6.5;

  static Offset _cubic(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final mt = 1 - t;
    final a = mt * mt * mt;
    final b = 3 * mt * mt * t;
    final c = 3 * mt * t * t;
    final d = t * t * t;
    return Offset(
      a * p0.dx + b * p1.dx + c * p2.dx + d * p3.dx,
      a * p0.dy + b * p1.dy + c * p2.dy + d * p3.dy,
    );
  }

  static Offset _cubicTangent(
      Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final mt = 1 - t;
    final a = 3 * mt * mt;
    final b = 6 * mt * t;
    final c = 3 * t * t;
    return Offset(
      a * (p1.dx - p0.dx) + b * (p2.dx - p1.dx) + c * (p3.dx - p2.dx),
      a * (p1.dy - p0.dy) + b * (p2.dy - p1.dy) + c * (p3.dy - p2.dy),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Опорные точки — в системе координат исходного SVG (28×400),
    // масштабируются под фактический размер виджета.
    const w = 28.0, h = 400.0;
    final sx = size.width / w;
    final sy = size.height / h;

    final segments = <_BraceSeg>[
      _BraceSeg(const Offset(28, 0), const Offset(16, 0), const Offset(14, 10),
          const Offset(14, 23), steps: 20),
      _BraceSeg(
          const Offset(14, 23), const Offset(14, 23), const Offset(14, 164),
          const Offset(14, 164),
          steps: 60, isLine: true),
      _BraceSeg(const Offset(14, 164), const Offset(14, 178), const Offset(8, 187),
          const Offset(0, 197), steps: 30),
      _BraceSeg(const Offset(0, 197), const Offset(8, 207), const Offset(14, 216),
          const Offset(14, 229), steps: 30),
      _BraceSeg(
          const Offset(14, 229), const Offset(14, 229), const Offset(14, 379),
          const Offset(14, 379),
          steps: 60, isLine: true),
      _BraceSeg(const Offset(14, 379), const Offset(14, 390), const Offset(16, 400),
          const Offset(28, 400), steps: 20),
    ];

    final centerPts = <Offset>[];
    final tangents = <Offset>[];
    for (final seg in segments) {
      for (int i = 0; i < seg.steps; i++) {
        final t = i / seg.steps;
        if (seg.isLine) {
          centerPts.add(Offset.lerp(seg.p0, seg.p3, t)!);
          tangents.add(seg.p3 - seg.p0);
        } else {
          centerPts.add(_cubic(seg.p0, seg.p1, seg.p2, seg.p3, t));
          tangents.add(_cubicTangent(seg.p0, seg.p1, seg.p2, seg.p3, t));
        }
      }
    }
    centerPts.add(const Offset(28, 400));
    tangents.add(const Offset(28, 400) - const Offset(16, 400));

    final n = centerPts.length;
    final outer = <Offset>[];
    final inner = <Offset>[];
    for (int i = 0; i < n; i++) {
      final t = i / (n - 1);
      final s = math.sin(2 * math.pi * t);
      final width = _wMin + (_wMax - _wMin) * s * s;
      final tan = tangents[i];
      final len = tan.distance;
      final normal = len < 1e-6
          ? const Offset(1, 0)
          : Offset(-tan.dy / len, tan.dx / len);
      final p = centerPts[i];
      outer.add(Offset((p.dx + normal.dx * width / 2) * sx,
          (p.dy + normal.dy * width / 2) * sy));
      inner.add(Offset((p.dx - normal.dx * width / 2) * sx,
          (p.dy - normal.dy * width / 2) * sy));
    }

    final path = Path()..moveTo(outer.first.dx, outer.first.dy);
    for (final o in outer.skip(1)) {
      path.lineTo(o.dx, o.dy);
    }
    for (final p in inner.reversed) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();

    canvas.drawPath(path, Paint()..color = _color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _BracePainter oldDelegate) => false;
}

class _BraceSeg {
  final Offset p0, p1, p2, p3;
  final int steps;
  final bool isLine;
  const _BraceSeg(this.p0, this.p1, this.p2, this.p3,
      {required this.steps, this.isLine = false});
}
