import 'package:flutter/material.dart';

import '../widgets/float_preloader.dart';

/// Экран загрузки (прелоадер) — показывает крупный логотип на кремовом фоне
/// пока приложение инициализируется. За логотипом — анимация карпов.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EC),
      body: SafeArea(
        child: Column(
          children: [
            // Логотип + анимация карпов на заднем плане
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Анимация карпов — на всю ширину экрана
                  // (рыбы плывут от левого края к правому)
                  Positioned.fill(
                    child: Image.asset(
                      'assets/icon/carp_swim.gif',
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                  // Логотип поверх анимации
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Image.asset(
                      'assets/icon/splash_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            // Поплавок-прелоадер
            const Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: FloatPreloader(
                label: 'Загрузка…',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
