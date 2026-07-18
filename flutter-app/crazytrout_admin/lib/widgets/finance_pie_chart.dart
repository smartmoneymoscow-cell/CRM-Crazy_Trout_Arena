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
        final narrow = constraints.maxWidth < 400;
        final donutSize = narrow ? 100.0 : 120.0;
        final donut = _buildDonut(donutSize);

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Структура выручки',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
          const SizedBox(height: 16),
          if (narrow) ...[
            Center(child: donut),
            const SizedBox(height: 14),
            _buildLegend(constraints.maxWidth - 36),
          ] else
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Flexible(child: _buildLegend(constraints.maxWidth - 36 - 16 - donutSize)),
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
        Text('${_fmtAmount(data.total)} ₽',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: size < 110 ? 11 : 13, fontWeight: FontWeight.w800, color: kInk, letterSpacing: -0.3)),
        Text('всего', style: TextStyle(fontSize: size < 110 ? 8 : 9, fontWeight: FontWeight.w500, color: kMuted2)),
      ]),
    ],
  ));

  Widget _buildLegend(double availableWidth) {
    // Адаптивные flex-пропорции под ширину
    final int labelFlex, pctFlex, amtFlex;
    if (availableWidth < 140) {
      labelFlex = 5; pctFlex = 2; amtFlex = 3;
    } else {
      labelFlex = 3; pctFlex = 2; amtFlex = 3;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < data.segments.length; i++) ...[
          _LegendRow(
            color: _segColors[i % _segColors.length],
            label: data.segments[i].label,
            pct: '${_fmtPct(data.pct(data.segments[i]))}%',
            amount: '${_fmtAmount(data.segments[i].amount)} ₽',
            labelFlex: labelFlex,
            pctFlex: pctFlex,
            amtFlex: amtFlex,
          ),
          if (i < data.segments.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

String _fmtPct(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

String _fmtAmount(double v) {
  if (v >= 1000000) {
    final k = v / 1000000;
    return '${k.toStringAsFixed(1).replaceAll('.', ',')} млн';
  }
  if (v >= 1000) {
    final k = v / 1000;
    return '${k.toStringAsFixed(1).replaceAll('.', ',')} тыс.';
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
  final int labelFlex, pctFlex, amtFlex;
  const _LegendRow({required this.color, required this.label, required this.pct, required this.amount,
    this.labelFlex = 3, this.pctFlex = 2, this.amtFlex = 3});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 8),
      Expanded(flex: labelFlex, child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kInk))),
      const SizedBox(width: 4),
      Flexible(
        flex: pctFlex,
        child: Text(pct, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted)),
      ),
      const SizedBox(width: 6),
      Flexible(
        flex: amtFlex,
        child: Text(amount, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kInk)),
      ),
    ]);
  }
}
