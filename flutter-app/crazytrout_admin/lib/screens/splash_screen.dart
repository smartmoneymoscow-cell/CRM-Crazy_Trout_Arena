import 'package:flutter/material.dart';

/// Экран загрузки (прелоадер) — показывает крупный логотип на кремовом фоне
/// пока приложение инициализируется.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Крупный логотип — 60% ширины экрана, но не более 320px
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320, maxHeight: 320),
                child: Image.asset(
                  'assets/icon/splash_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              // Индикатор загрузки
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFFE8912B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
