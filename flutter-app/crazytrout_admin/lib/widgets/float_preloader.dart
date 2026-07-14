import 'dart:math';
import 'package:flutter/material.dart';

/// Анимированный поплавок на волнах — прелоадер поиска Bluetooth-принтеров.
/// Поплавок качается на волнах, под ним — прогресс-бар поиска.
///
/// Использование:
/// ```dart
/// FloatPreloader(
///   progress: 0.6,        // 0.0 → 1.0, null = indeterminate
///   label: 'Ищем принтеры…',
/// )
/// ```
class FloatPreloader extends StatefulWidget {
  /// Текст под поплавком.
  final String label;

  /// Прогресс 0.0–1.0. Если null — бесконечная анимация (indeterminate).
  final double? progress;

  /// Длительность indeterminate-цикла.
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
    // Поплавок: покачивание вверх-вниз
    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Волны: движение волнистой линии
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // Прогресс-бар (indeterminate)
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
    const double width = 200;
    const double height = 160;

    return SizedBox(
      width: width,
      height: height,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // === Поплавок + волны ===
          SizedBox(
            width: width,
            height: 100,
            child: AnimatedBuilder(
              animation: Listenable.merge([_bobController, _waveController]),
              builder: (context, _) {
                return CustomPaint(
                  size: const Size(width, 100),
                  painter: _FloatPainter(
                    bobPhase: _bobController.value,
                    wavePhase: _waveController.value,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // === Прогресс-бар ===
          _buildProgressBar(),
          const SizedBox(height: 8),
          // === Текст ===
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
    const barWidth = 160.0;
    const barHeight = 6.0;

    if (widget.progress != null) {
      // Determinate
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

    // Indeterminate — бегущий градиент
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        final t = _progressController.value;
        return Container(
          width: barWidth,
          height: barHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFF3EEE4),
            borderRadius: BorderRadius.circular(3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Align(
              alignment: Alignment(-1.0 + 2.0 * t, 0),
              child: Container(
                width: barWidth * 0.4,
                height: barHeight,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4A85A), Color(0xFFE89829)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Painter: рисует волны и поплавок.
class _FloatPainter extends CustomPainter {
  final double bobPhase; // 0→1→0 (ping-pong)
  final double wavePhase; // 0→1 цикл

  _FloatPainter({required this.bobPhase, required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final waterY = size.height * 0.58;

    // === Волны ===
    final wavePaint = Paint()
      ..color = const Color(0xFFB8D4E3).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int row = 0; row < 3; row++) {
      final y = waterY + row * 12.0;
      final path = Path();
      for (double x = 0; x <= size.width; x += 1) {
        final wave =
            sin((x / size.width * 2 * pi) + wavePhase * 2 * pi + row * 0.8) *
                4.0;
        if (x == 0) {
          path.moveTo(x, y + wave);
        } else {
          path.lineTo(x, y + wave);
        }
      }
      canvas.drawPath(path, wavePaint..strokeWidth = 1.5 - row * 0.3);
    }

    // === Поплавок ===
    final bobOffset = sin(bobPhase * pi) * 6.0;
    final floatTop = waterY - 32 + bobOffset;
    final floatBottom = waterY + 4 + bobOffset;

    // Ножка (тонкая линия сверху)
    final stemPaint = Paint()
      ..color = const Color(0xFFE89829)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, floatTop - 18),
      Offset(cx, floatTop + 4),
      stemPaint,
    );

    // Флаг
    final flagPath = Path()
      ..moveTo(cx, floatTop - 18)
      ..lineTo(cx + 12, floatTop - 12)
      ..lineTo(cx, floatTop - 6)
      ..close();
    canvas.drawPath(
        flagPath,
        Paint()
          ..color = const Color(0xFFC9302C));

    // Верхняя часть (красная)
    final topOval = RRect.fromLTRBR(
      cx - 7, floatTop, cx + 7, floatTop + 16,
      const Radius.circular(7),
    );
    canvas.drawRRect(
        topOval,
        Paint()
          ..color = const Color(0xFFC9302C));

    // Нижняя часть (жёлтая)
    final bottomOval = RRect.fromLTRBR(
      cx - 5, floatTop + 14, cx + 5, floatBottom,
      const Radius.circular(5),
    );
    canvas.drawRRect(
        bottomOval,
        Paint()
          ..color = const Color(0xFFE89829));

    // Киль (маленький кружок внизу)
    canvas.drawCircle(
      Offset(cx, floatBottom + 3),
      3,
      Paint()..color = const Color(0xFFD4A85A),
    );

    // Блик на красной части
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - 2, floatTop + 7),
        width: 4,
        height: 8,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _FloatPainter old) =>
      old.bobPhase != bobPhase || old.wavePhase != wavePhase;
}
