import 'dart:math';
import 'package:flutter/material.dart';

/// Анимированный поплавок-бобber с анимацией поклёвки.
///
/// Использование:
/// ```dart
/// FloatPreloader(
///   label: 'Ищем принтеры…',
///   progress: null, // indeterminate
/// )
/// ```
///
/// Для анимации поклёвки:
/// ```dart
/// final key = GlobalKey<FloatPreloaderState>();
/// FloatPreloader(key: key, ...)
/// key.currentState?.triggerBite();
/// ```
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
  FloatPreloaderState createState() => FloatPreloaderState();
}

class FloatPreloaderState extends State<FloatPreloader>
    with TickerProviderStateMixin {
  late final AnimationController _bobController;
  late final AnimationController _waveController;
  late final AnimationController _progressController;
  late final AnimationController _biteController;

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

    _biteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
  }

  @override
  void dispose() {
    _bobController.dispose();
    _waveController.dispose();
    _progressController.dispose();
    _biteController.dispose();
    super.dispose();
  }

  /// Запускает анимацию поклёвки.
  void triggerBite() {
    if (_biteController.isAnimating) return;
    _biteController.forward(from: 0).then((_) {
      _biteController.reset();
    });
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
              animation: Listenable.merge([
                _bobController,
                _waveController,
                _biteController,
              ]),
              builder: (context, _) {
                return CustomPaint(
                  size: const Size(width, 120),
                  painter: _FloatPainter(
                    bobPhase: _bobController.value,
                    wavePhase: _waveController.value,
                    biteValue: _biteController.value,
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

/// Painter: классический bobber + анимация поклёвки.
class _FloatPainter extends CustomPainter {
  final double bobPhase;
  final double wavePhase;
  final double biteValue; // 0=idle, 0..1=bite animation cycle

  _FloatPainter({
    required this.bobPhase,
    required this.wavePhase,
    required this.biteValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final waterY = size.height * 0.58;
    final bob = sin(bobPhase * pi) * 6.0;

    // Bite animation offsets
    double dipOffset = 0;
    double tilt = 0;
    if (biteValue > 0) {
      if (biteValue < 0.12) {
        // Quick dip
        final t = _easeOutCubic(biteValue / 0.12);
        dipOffset = t * 30;
        tilt = t * 0.12;
      } else if (biteValue < 0.3) {
        // Submerge
        final t = _easeInOutCubic((biteValue - 0.12) / 0.18);
        dipOffset = 30 + t * 30;
        tilt = 0.12 + t * 0.08;
      } else if (biteValue < 0.6) {
        // Rise with bounce
        final t = _easeOutBounce((biteValue - 0.3) / 0.3);
        dipOffset = 60 * (1 - t);
        tilt = 0.2 * (1 - t);
      } else {
        // Wobble settle
        final t = (biteValue - 0.6) / 0.4;
        dipOffset = sin(t * pi * 6) * 3 * (1 - t);
        tilt = sin(t * pi * 5) * 0.02 * (1 - t);
      }
    }

    final waveOff = wavePhase * 2 * pi;

    // === Water surface ===
    final wavePath = Path();
    for (double x = 0; x <= size.width; x += 1) {
      final y = waterY +
          sin((x / size.width) * 3 * pi + waveOff) * 3.0 +
          sin((x / size.width) * 5.5 * pi - waveOff * 0.6) * 1.5;
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

    final fillPath = Path.from(wavePath);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(
      fillPath,
      Paint()..color = const Color(0xFF2A6A7E).withValues(alpha: 0.08),
    );

    // === Float ===
    canvas.save();
    canvas.translate(cx, waterY - 2 + bob + dipOffset);
    canvas.rotate(tilt);

    // --- Antenna ---
    // Orange tapered tip
    final tipPath = Path()
      ..moveTo(0, -60)
      ..lineTo(-3, -48)
      ..lineTo(3, -48)
      ..close();
    canvas.drawPath(tipPath, Paint()..color = const Color(0xFFE89829));

    // Orange cylinder
    canvas.drawRect(
      const Rect.fromLTWH(-3, -48, 6, 14),
      Paint()..color = const Color(0xFFE89829),
    );

    // White cylinder
    canvas.drawRect(
      const Rect.fromLTWH(-3, -34, 6, 12),
      Paint()..color = const Color(0xFFF5F0E3),
    );

    // Black ring
    canvas.drawRect(
      const Rect.fromLTWH(-3, -22, 6, 3),
      Paint()..color = const Color(0xFF14130F),
    );

    // --- Body ---
    // White bottom sphere (wider)
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: 40, height: 36),
      Paint()..color = const Color(0xFFF5F0E3),
    );
    // Subtle outline
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: 40, height: 36),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Red top sphere (smaller)
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -16), width: 28, height: 28),
      Paint()..color = const Color(0xFFC9302C),
    );

    // Glossy highlight
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-4, -20), width: 8, height: 14),
      Paint()..color = Colors.white.withValues(alpha: 0.32),
    );

    // Dividing line
    canvas.drawLine(
      const Offset(-20, 2),
      const Offset(20, 2),
      Paint()
        ..color = const Color(0xFF8C8576).withValues(alpha: 0.4)
        ..strokeWidth = 1,
    );

    // --- Keel ---
    canvas.drawLine(
      const Offset(0, 22),
      const Offset(0, 38),
      Paint()
        ..color = const Color(0xFF5C4D2F)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 40), width: 7, height: 5),
      Paint()..color = const Color(0xFF3A3225),
    );

    canvas.restore();
  }

  double _easeOutCubic(double t) => 1 - pow(1 - t, 3).toDouble();
  double _easeInOutCubic(double t) =>
      t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2;
  double _easeOutBounce(double t) {
    if (t < 1 / 2.75) return 7.5625 * t * t;
    if (t < 2 / 2.75) {
      t -= 1.5 / 2.75;
      return 7.5625 * t * t + 0.75;
    }
    if (t < 2.5 / 2.75) {
      t -= 2.25 / 2.75;
      return 7.5625 * t * t + 0.9375;
    }
    t -= 2.625 / 2.75;
    return 7.5625 * t * t + 0.984375;
  }

  @override
  bool shouldRepaint(covariant _FloatPainter old) =>
      old.bobPhase != bobPhase ||
      old.wavePhase != wavePhase ||
      old.biteValue != biteValue;
}
