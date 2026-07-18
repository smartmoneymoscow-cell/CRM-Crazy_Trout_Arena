import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/revenue_dynamics_data.dart';
import '../theme/app_theme.dart';


class RevenueDynamicsChart extends StatefulWidget {
  final RevenueDynamicsData data;
  /// If non-null, auto-select view mode based on period duration.
  /// 'quarter' or 'all' → monthly, 'month' → monthly, 'week' → weekly, 'today' → weekly.
  final String? periodKey;
  const RevenueDynamicsChart({super.key, required this.data, this.periodKey});

  @override
  State<RevenueDynamicsChart> createState() => _RevenueDynamicsChartState();
}

class _RevenueDynamicsChartState extends State<RevenueDynamicsChart> {
  // Default to monthly (which shows quarterly-like aggregated data)
  bool _monthly = true;

  @override
  void didUpdateWidget(covariant RevenueDynamicsChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-switch based on period if periodKey changed
    if (widget.periodKey != oldWidget.periodKey && widget.periodKey != null) {
      final pk = widget.periodKey!;
      if (pk == 'today' || pk == 'week') {
        _monthly = false; // show weekly for short periods
      } else {
        _monthly = true; // show monthly for month/quarter/all
      }
    }
  }

  List<PeriodPoint> get _points => _monthly ? widget.data.monthly : widget.data.weekly;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kPaper, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kHairline2, width: 0.5),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Динамика показателей',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
        const SizedBox(height: 16),
        Row(children: [
          _legendDot(const Color(0xFFE8912B), 'Выручка'),
          const SizedBox(width: 16),
          _legendDot(const Color(0xFF4A7C59), 'Маржа'),
          const SizedBox(width: 16),
          _legendDot(const Color(0xFFC0392B), 'Расходы'),
        ]),
        const SizedBox(height: 16),
        SizedBox(height: 180, child: ClipRect(
          child: CustomPaint(
            size: Size(MediaQuery.of(context).size.width - 36, 180),
            painter: _ChartPainter(data: _points),
          ),
        )),
        const SizedBox(height: 12),
        SizedBox(height: 20, child: Row(
          children: _points.map((d) => Expanded(
            child: Text(d.label, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: kMuted2)),
          )).toList(),
        )),
        const SizedBox(height: 16),
        Center(child: Container(
          decoration: BoxDecoration(color: kFill, borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.all(3),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _toggleBtn('По месяцам', _monthly, () => setState(() => _monthly = true)),
            _toggleBtn('По неделям', !_monthly, () => setState(() => _monthly = false)),
          ]),
        )),
      ]),
    );
  }

  Widget _legendDot(Color color, String label) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 5),
    Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: kInk)),
  ]);

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))] : null,
      ),
      child: Text(label, style: TextStyle(fontSize: 12,
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        color: active ? kInk : kMuted2)),
    ),
  );
}

class _ChartPainter extends CustomPainter {
  final List<PeriodPoint> data;
  _ChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final allValues = <double>[];
    for (final d in data) { allValues.addAll([d.revenue, d.margin, d.expenses]); }
    final maxVal = allValues.reduce(math.max);
    if (maxVal <= 0) return;

    final cl = 50.0, cr = size.width - 8, ct = 8.0, cb = size.height - 8;
    final cw = cr - cl, ch = cb - ct;
    final gridPaint = Paint()..color = const Color(0xFFEFE8D8)..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = ct + ch * i / 4;
      canvas.drawLine(Offset(cl, y), Offset(cr, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(text: _fmtShort(maxVal - maxVal * i / 4),
          style: const TextStyle(fontSize: 9, color: Color(0xFF9C9484))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cl - tp.width - 4, y - tp.height / 2));
    }

    _drawLine(canvas, data.map((d) => d.revenue).toList(), const Color(0xFFE8912B), cl, ct, cw, ch, maxVal);
    _drawLine(canvas, data.map((d) => d.margin).toList(), const Color(0xFF4A7C59), cl, ct, cw, ch, maxVal);
    _drawLine(canvas, data.map((d) => d.expenses).toList(), const Color(0xFFC0392B), cl, ct, cw, ch, maxVal);
  }

  void _drawLine(Canvas canvas, List<double> v, Color c, double l, double t, double w, double h, double max) {
    if (v.length < 2) return;
    final paint = Paint()..color = c..style = PaintingStyle.stroke
      ..strokeWidth = 2.5..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final dx = w / (v.length - 1);
    Offset off(int i) => Offset(l + i * dx, t + h - (v[i] / max) * h);
    final path = Path()..moveTo(off(0).dx, off(0).dy);
    for (int i = 0; i < v.length - 1; i++) {
      final p0 = off(i), p1 = off(i + 1);
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      if (i == v.length - 2) path.lineTo(p1.dx, p1.dy);
    }
    canvas.drawPath(path, paint);
    final dot = Paint()..color = c;
    for (int i = 0; i < v.length; i++) { canvas.drawCircle(off(i), 3, dot); }
  }

  String _fmtShort(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.round().toString();
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => old.data != data;
}
