import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/sales_decomposition.dart';
import '../theme/app_theme.dart';


const _segColors = <Color>[
  Color(0xFFE8912B), Color(0xFF6B4226), Color(0xFF9C5A3C),
  Color(0xFF4A7C59), Color(0xFF8B7355), Color(0xFFD4C4A8),
];

const _segGradients = <List<Color>>[
  [Color(0xFFE8912B), Color(0xFFF2A84D)],
  [Color(0xFF6B4226), Color(0xFF8B5A3A)],
  [Color(0xFF9C5A3C), Color(0xFFB87050)],
  [Color(0xFF4A7C59), Color(0xFF5FA87A)],
  [Color(0xFF8B7355), Color(0xFFA88960)],
  [Color(0xFFD4C4A8), Color(0xFFE0D4BA)],
];

class FinancePieChart extends StatelessWidget {
  final SalesDecomposition data;
  const FinancePieChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kPaper, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kHairline2, width: 0.5),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: LayoutBuilder(builder: (context, constraints) {
        final w = constraints.maxWidth;
        // Адаптивный размер диаграммы — уменьшается при узком экране
        final donutSize = w < 340 ? 80.0 : w < 400 ? 95.0 : 110.0;
        final donut = _buildDonut(donutSize);

        // Легенда: максимальная ширина = общая - диаграмма - отступ - padding
        final legendMaxW = w - donutSize - 16 - 36;

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Структура выручки',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
          const SizedBox(height: 16),
          // Всегда Row: легенда слева, диаграмма справа
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: legendMaxW),
              child: _buildLegend(legendMaxW),
            ),
            const SizedBox(width: 16),
            donut,
          ]),
        ]);
      }),
    );
  }

  Widget _buildDonut(double size) => SizedBox(width: size, height: size, child: Stack(
    alignment: Alignment.center,
    children: [
      ClipRect(
        child: CustomPaint(size: Size(size, size),
          painter: _DonutPainter(segments: data.segments, colors: _segColors, total: data.total)),
      ),
      Column(mainAxisSize: MainAxisSize.min, children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('${_fmtAmount(data.total)} ₽',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: size < 110 ? 11 : 13, fontWeight: FontWeight.w800, color: kInk, letterSpacing: -0.3)),
        ),
        Text('всего', style: TextStyle(fontSize: size < 110 ? 8 : 9, fontWeight: FontWeight.w500, color: kMuted2)),
      ]),
    ],
  ));

  Widget _buildLegend(double availableWidth) {
    // label — Flexible (сжимается), pct/amt — фиксированные ширины.
    // Отступ label→pct = 4px (как pct→amt), не растягивается.
    const double pctW = 40;  // «100,0%» — достаточно
    const double amtW = 72;  // «100,0 млн» — 9 символов, font 13 bold ≈ 8px/char
    const double gap = 4;    // одинаковый отступ между колонками
    const double dotSpace = 10 + 6; // dot(10) + gap(6)

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < data.segments.length; i++) ...[
          _LegendRow(
            color: _segColors[i % _segColors.length],
            label: data.segments[i].label,
            pct: '${_fmtPct(data.pct(data.segments[i]))}%',
            amount: _fmtAmount(data.segments[i].amount),
            pctWidth: pctW,
            amtWidth: amtW,
            gap: gap,
          ),
          if (i < data.segments.length - 1) const SizedBox(height: 11),
        ],
      ],
    );
  }
}

String _fmtPct(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

String _fmtAmount(double v) {
  if (v >= 1000000) {
    final k = v / 1000000;
    final s = k.toStringAsFixed(1).replaceAll('.', ',');
    return '$s млн';
  }
  if (v >= 1000) {
    final k = v / 1000;
    final s = k.toStringAsFixed(1).replaceAll('.', ',');
    // 168,0 → 168 (убираем .0 для круглых)
    return '${s.endsWith(',0') ? s.substring(0, s.length - 2) : s} тыс.';
  }
  return v.round().toString();
}

class _DonutPainter extends CustomPainter {
  final List<SalesSegment> segments;
  final List<Color> colors;
  final double total;
  _DonutPainter({required this.segments, required this.colors, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 20.0;
    final r = radius - strokeWidth / 2 - 1;

    if (total <= 0 || segments.isEmpty) {
      canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFE1DCCF)
        ..style = PaintingStyle.stroke..strokeWidth = strokeWidth);
      return;
    }

    double startAngle = -math.pi / 2;
    for (int i = 0; i < segments.length; i++) {
      final sweep = 2 * math.pi * (segments[i].amount / total);
      final gradColors = _segGradients[i % _segGradients.length];
      canvas.drawArc(Rect.fromCircle(center: center, radius: r), startAngle, sweep, false,
        Paint()
          ..shader = LinearGradient(colors: gradColors,
            begin: Alignment(math.cos(startAngle), math.sin(startAngle)),
            end: Alignment(math.cos(startAngle + sweep), math.sin(startAngle + sweep)),
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.butt);

      if (sweep > 0.02) {
        final sepAngle = startAngle + sweep;
        canvas.drawLine(
          center + Offset(math.cos(sepAngle) * (r - strokeWidth / 2 - 1), math.sin(sepAngle) * (r - strokeWidth / 2 - 1)),
          center + Offset(math.cos(sepAngle) * (r + strokeWidth / 2 + 1), math.sin(sepAngle) * (r + strokeWidth / 2 + 1)),
          Paint()..color = kWhite..strokeWidth = 2.5..strokeCap = StrokeCap.round);
      }
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.segments != segments || old.total != total;
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String pct;
  final String amount;
  final double pctWidth;
  final double amtWidth;
  final double gap;
  const _LegendRow({required this.color, required this.label, required this.pct, required this.amount,
    this.pctWidth = 40, this.amtWidth = 72, this.gap = 4});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      // Цветной кружок
      Container(width: 10, height: 10,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      // Название — Flexible, сжимается при нехватке места
      Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kInk))),
      SizedBox(width: gap),
      // Процент — фиксированная ширина
      SizedBox(width: pctWidth, child: Text(pct, textAlign: TextAlign.right, maxLines: 1,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted))),
      SizedBox(width: gap),
      // Сумма — фиксированная ширина
      SizedBox(width: amtWidth, child: Text(amount, textAlign: TextAlign.right, maxLines: 1,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kInk))),
    ]);
  }
}
