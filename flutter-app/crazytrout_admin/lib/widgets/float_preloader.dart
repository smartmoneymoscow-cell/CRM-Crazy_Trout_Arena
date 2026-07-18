import 'package:flutter/material.dart';

/// Прелоадер — вращающийся круг с текстом.
///
/// Использование:
/// ```dart
/// FloatPreloader(
///   label: 'Ищем принтеры…',
///   progress: null, // indeterminate
/// )
/// ```
class FloatPreloader extends StatefulWidget {
  final String label;
  final double? progress;

  const FloatPreloader({
    super.key,
    this.label = 'Ищем принтеры…',
    this.progress,
  });

  @override
  FloatPreloaderState createState() => FloatPreloaderState();
}

class FloatPreloaderState extends State<FloatPreloader> {
  @deprecated
  void triggerBite() {}

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 65,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: widget.progress != null
                ? CircularProgressIndicator(
                    value: widget.progress!.clamp(0.0, 1.0),
                    strokeWidth: 3,
                    color: const Color(0xFFE89829),
                    backgroundColor: const Color(0xFFF3EEE4),
                  )
                : const CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFFE89829),
                    backgroundColor: Color(0xFFF3EEE4),
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
