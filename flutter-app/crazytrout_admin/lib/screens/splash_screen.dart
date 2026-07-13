import 'package:flutter/material.dart';

/// Экран загрузки (прелоадер) — показывает крупный логотип на кремовом фоне
/// пока приложение инициализируется.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EC),
      body: SafeArea(
        child: Column(
          children: [
            // Крупный логотип на весь экран (с прозрачным фоном — без белой
            // подложки вокруг), а не маленький бокс 320×320.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Image.asset(
                  'assets/icon/splash_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFFE8912B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
