import 'package:flutter/material.dart';

/// Прелоадер — анимированный поплавок с надписью.
///
/// GIF-анимация поплавка (30 кадров, 10 fps, цикл).
class FloatPreloader extends StatefulWidget {
  final String label;
  final double? progress;

  const FloatPreloader({
    super.key,
    this.label = 'Загрузка…',
    this.progress,
  });

  @override
  State<FloatPreloader> createState() => _FloatPreloaderState();
}

class _FloatPreloaderState extends State<FloatPreloader> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 75,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Image.asset(
              'assets/icon/float_bobber.gif',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8C8576),
            ),
          ),
        ],
      ),
    );
  }
}
