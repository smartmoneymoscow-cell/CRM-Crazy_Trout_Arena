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
            // Анимация карпов — в самом верху, на всю ширину
            SizedBox(
              width: double.infinity,
              height: 140,
              child: Image.asset(
                'assets/icon/carp_swim.gif',
                fit: BoxFit.fitWidth,
                alignment: Alignment.center,
                filterQuality: FilterQuality.medium,
              ),
            ),
            // Логотип по центру
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Image.asset(
                    'assets/icon/splash_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
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
