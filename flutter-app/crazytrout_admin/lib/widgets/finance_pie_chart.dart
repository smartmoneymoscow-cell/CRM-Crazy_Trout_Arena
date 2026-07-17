import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/sales_decomposition.dart';

const _ink = Color(0xFF14130F);
const _paper = Color(0xFFFBF6EC);
const _fill = Color(0xFFF3EEE4);
const _orange = Color(0xFFE8912B);
const _hairline2 = Color(0xFFE7E0D1);
const _muted = Color(0xFF8C8576);
const _muted2 = Color(0xFF9C9484);
const _white = Color(0xFFFFFFFF);

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
        color: _paper, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _hairline2, width: 0.5),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Структура выручки',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Flexible(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < data.segments.length; i++) ...[
                _LegendRow(
                  color: _segColors[i % _segColors.length],
                  label: data.segments[i].label,
                  pct: '${_fmtPct(data.pct(data.segments[i]))}%',
                  amount: '${_fmtAmount(data.segments[i].amount)} ₽',
                ),
                if (i < data.segments.length - 1) const SizedBox(height: 12),
              ],
            ],
          )),
          const SizedBox(width: 16),
          SizedBox(width: 120, height: 120, child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRect(
                child: CustomPaint(size: const Size(120, 120),
                  painter: _DonutPainter(segments: data.segments, colors: _segColors, total: data.total)),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${_fmtAmount(data.total)} ₽',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.3)),
                const Text('всего', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: _muted2)),
              ]),
            ],
          )),
        ]),
      ]),
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
    const strokeWidth = 24.0;

    if (total <= 0 || segments.isEmpty) {
      canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFE1DCCF)
        ..style = PaintingStyle.stroke..strokeWidth = strokeWidth);
      return;
    }

    double startAngle = -math.pi / 2;
    for (int i = 0; i < segments.length; i++) {
      final sweep = 2 * math.pi * (segments[i].amount / total);
      final gradColors = _segGradients[i % _segGradients.length];
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep, false,
        Paint()
          ..shader = LinearGradient(colors: gradColors,
            begin: Alignment(math.cos(startAngle), math.sin(startAngle)),
            end: Alignment(math.cos(startAngle + sweep), math.sin(startAngle + sweep)),
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.butt);

      if (sweep > 0.02) {
        final sepAngle = startAngle + sweep;
        canvas.drawLine(
          center + Offset(math.cos(sepAngle) * (radius - strokeWidth / 2 - 1), math.sin(sepAngle) * (radius - strokeWidth / 2 - 1)),
          center + Offset(math.cos(sepAngle) * (radius + strokeWidth / 2 + 1), math.sin(sepAngle) * (radius + strokeWidth / 2 + 1)),
          Paint()..color = _white..strokeWidth = 2.5..strokeCap = StrokeCap.round);
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
  const _LegendRow({required this.color, required this.label, required this.pct, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 8),
      Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _ink))),
      Text(pct, textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _muted)),
      const SizedBox(width: 8),
      Text(amount, textAlign: TextAlign.right, maxLines: 1, softWrap: false,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
    ]);
  }
}
