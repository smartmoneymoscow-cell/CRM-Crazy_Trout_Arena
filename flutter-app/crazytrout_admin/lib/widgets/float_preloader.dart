import 'dart:math';
import 'package:flutter/material.dart';

/// Анимированный поплавок-бобber — прелоадер поиска Bluetooth-принтеров.
class FloatPreloader extends StatefulWidget {
  final String label;
  final double? progress;
  final Duration cycleDuration;

  const FloatPreloader({
    super.key,
    this.label = 'Ищем принтеры…',
    this.progress,
    this.cycleDuration = const Duration(seconds: 4),
  });

  @override
  State<FloatPreloader> createState() => _FloatPreloaderState();
}

class _FloatPreloaderState extends State<FloatPreloader>
    with TickerProviderStateMixin {
  late final AnimationController _bobController;
  late final AnimationController _waveController;
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _progressController = AnimationController(
      vsync: this,
      duration: widget.cycleDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _bobController.dispose();
    _waveController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double width = 220;
    const double height = 180;

    return SizedBox(
      width: width,
      height: height,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: width,
            height: 120,
            child: AnimatedBuilder(
              animation: Listenable.merge([_bobController, _waveController]),
              builder: (context, _) {
                return CustomPaint(
                  size: const Size(width, 120),
                  painter: _FloatPainter(
                    bobPhase: _bobController.value,
                    wavePhase: _waveController.value,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          _buildProgressBar(),
          const SizedBox(height: 8),
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8C8576),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    const barWidth = 180.0;
    const barHeight = 6.0;

    if (widget.progress != null) {
      return Container(
        width: barWidth,
        height: barHeight,
        decoration: BoxDecoration(
          color: const Color(0xFFF3EEE4),
          borderRadius: BorderRadius.circular(3),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: widget.progress!.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD4A85A), Color(0xFFE89829)],
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      );
    }

    // Indeterminate — заполняется слева направо, сброс
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, _) {
        final t = _progressController.value;
        return Container(
          width: barWidth,
          height: barHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFF3EEE4),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: barWidth * t,
              height: barHeight,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD4A85A), Color(0xFFE89829)],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Painter: классический поплавок-бобber (красный верх, белый низ, антенна, киль).
class _FloatPainter extends CustomPainter {
  final double bobPhase;
  final double wavePhase;

  _FloatPainter({required this.bobPhase, required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final waterY = size.height * 0.6;
    final bob = sin(bobPhase * pi) * 8.0;

    // === Water surface — single line ===
    final wavePath = Path();
    for (double x = 0; x <= size.width; x += 1) {
      final y = waterY +
          sin((x / size.width) * 3 * pi + wavePhase * 2 * pi) * 3.0 +
          sin((x / size.width) * 5.5 * pi - wavePhase * 1.2 * pi) * 1.5;
      if (x == 0) {
        wavePath.moveTo(x, y);
      } else {
        wavePath.lineTo(x, y);
      }
    }
    canvas.drawPath(
      wavePath,
      Paint()
        ..color = const Color(0xFF2A6A7E).withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Water fill
    final fillPath = Path.from(wavePath);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(
      fillPath,
      Paint()..color = const Color(0xFF2A6A7E).withValues(alpha: 0.08),
    );

    // === Float ===
    final fx = cx;
    final fy = waterY - 5 + bob;

    // --- Antenna (thin rod) ---
    final antTop = fy - 48;
    final antBot = fy - 16;
    canvas.drawLine(
      Offset(fx, antTop),
      Offset(fx, antBot),
      Paint()
        ..color = const Color(0xFF5C4D2F)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Antenna tip ball
    canvas.drawCircle(
      Offset(fx, antTop - 3),
      3,
      Paint()..color = const Color(0xFFE89829),
    );

    // --- Body: classic pear shape ---
    final bodyCY = fy - 4;
    const rx = 16.0;
    const ry = 20.0;

    // Red top half
    canvas.drawArc(
      Rect.fromCenter(center: Offset(fx, bodyCY), width: rx * 2, height: ry * 2),
      pi, // start angle (top)
      -pi, // sweep (half circle, left to right)
      false,
      Paint()..color = const Color(0xFFC9302C),
    );

    // Glossy highlight
    canvas.drawOval(
      Rect.fromCenter(center: Offset(fx - 5, bodyCY - 8), width: 10, height: 18),
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );

    // White/cream bottom half
    canvas.drawArc(
      Rect.fromCenter(center: Offset(fx, bodyCY), width: rx * 2, height: ry * 1.2),
      0,
      pi,
      false,
      Paint()..color = const Color(0xFFF5F0E3),
    );

    // Dividing line
    canvas.drawLine(
      Offset(fx - rx, bodyCY),
      Offset(fx + rx, bodyCY),
      Paint()
        ..color = const Color(0xFF8C8576)
        ..strokeWidth = 1.2,
    );

    // --- Lower stem ---
    final stemBot = bodyCY + ry * 0.6;
    final keelTop = stemBot + 5;
    canvas.drawLine(
      Offset(fx, stemBot),
      Offset(fx, keelTop),
      Paint()
        ..color = const Color(0xFF5C4D2F)
        ..strokeWidth = 2,
    );

    // --- Keel wire ---
    final keelBot = fy + 24;
    canvas.drawLine(
      Offset(fx, keelTop),
      Offset(fx, keelBot),
      Paint()
        ..color = const Color(0xFF8C8576)
        ..strokeWidth = 1.5,
    );

    // Keel weight
    canvas.drawOval(
      Rect.fromCenter(center: Offset(fx, keelBot), width: 8, height: 6),
      Paint()..color = const Color(0xFF6B5B3A),
    );
  }

  @override
  bool shouldRepaint(covariant _FloatPainter old) =>
      old.bobPhase != bobPhase || old.wavePhase != wavePhase;
}
