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
  late final AnimationController _progressController;
  late final AnimationController _biteController;

  @override
  void initState() {
    super.initState();
    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

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
    const double width = 160;
    const double height = 140;

    return SizedBox(
      width: width,
      height: height,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: width,
            height: 90,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _bobController,
                _biteController,
              ]),
              builder: (context, _) {
                return CustomPaint(
                  size: const Size(width, 90),
                  painter: _FloatPainter(
                    bobPhase: _bobController.value,
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
    const barWidth = 130.0;
    const barHeight = 4.0;

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
  final double biteValue; // 0=idle, 0..1=bite animation cycle

  _FloatPainter({
    required this.bobPhase,
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
        dipOffset = t * 20;
        tilt = t * 0.12;
      } else if (biteValue < 0.3) {
        // Submerge
        final t = _easeInOutCubic((biteValue - 0.12) / 0.18);
        dipOffset = 20 + t * 20;
        tilt = 0.12 + t * 0.08;
      } else if (biteValue < 0.6) {
        // Rise with bounce
        final t = _easeOutBounce((biteValue - 0.3) / 0.3);
        dipOffset = 40 * (1 - t);
        tilt = 0.2 * (1 - t);
      } else {
        // Wobble settle
        final t = (biteValue - 0.6) / 0.4;
        dipOffset = sin(t * pi * 6) * 3 * (1 - t);
        tilt = sin(t * pi * 5) * 0.02 * (1 - t);
      }
    }

    // === Water — simple straight line ===
    canvas.drawRect(
      Rect.fromLTWH(0, waterY, size.width, size.height - waterY),
      Paint()..color = const Color(0xFF2A6A7E).withOpacity(0.08),
    );
    canvas.drawLine(
      Offset(0, waterY),
      Offset(size.width, waterY),
      Paint()
        ..color = const Color(0xFF2A6A7E).withOpacity(0.25)
        ..strokeWidth = 1,
    );

    // === Float ===
    canvas.save();
    canvas.translate(cx, waterY - 2 + bob + dipOffset);
    canvas.rotate(tilt);

    // --- Antenna: long thin red stick with ball on top ---
    const double stickW = 2.5;
    const double antTop = -65;
    const double antBot = -14;

    // Red stick
    canvas.drawRect(
      Rect.fromLTWH(-stickW / 2, antTop + 6, stickW, antBot - antTop - 6),
      Paint()..color = const Color(0xFFC9302C),
    );

    // White stripe across
    const double stripeY = antTop + (antBot - antTop) * 0.45;
    canvas.drawRect(
      Rect.fromLTWH(-stickW / 2 - 0.5, stripeY, stickW + 1, 3),
      Paint()..color = const Color(0xFFF5F0E3),
    );

    // Red ball on top
    canvas.drawCircle(
      const Offset(0, antTop + 6),
      4.5,
      Paint()..color = const Color(0xFFC9302C),
    );
    // Highlight
    canvas.drawCircle(
      const Offset(-1.5, antTop + 4.5),
      1.5,
      Paint()..color = Colors.white.withOpacity(0.45),
    );

    // --- Body: elongated teardrop ---
    // Red top (elongated oval)
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -8), width: 16, height: 28),
      Paint()..color = const Color(0xFFC9302C),
    );
    // Glossy
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-2, -12), width: 5, height: 10),
      Paint()..color = Colors.white.withOpacity(0.35),
    );

    // White bottom (slightly wider)
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 8), width: 18, height: 26),
      Paint()..color = const Color(0xFFF5F0E3),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 8), width: 18, height: 26),
      Paint()
        ..color = Colors.black.withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Dividing line
    canvas.drawLine(
      const Offset(-9, 0),
      const Offset(9, 0),
      Paint()
        ..color = const Color(0xFF8C8576).withOpacity(0.4)
        ..strokeWidth = 0.8,
    );

    // --- Keel ---
    canvas.drawLine(
      const Offset(0, 21),
      const Offset(0, 32),
      Paint()
        ..color = const Color(0xFF5C4D2F)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 33), width: 5, height: 3.6),
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
      old.biteValue != biteValue;
}
