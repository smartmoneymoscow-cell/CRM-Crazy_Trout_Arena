import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_shell.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Фиксируем вертикальную ориентацию (портрет) — чек-касса не нужна в альбомной.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const CrazyTroutAdminApp());
}

class CrazyTroutAdminApp extends StatelessWidget {
  const CrazyTroutAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crazy Trout Arena · Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFFBF6EC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8912B),
          brightness: Brightness.light,
        ),
      ),
      home: const _AppStartup(),
    );
  }
}

/// Показывает SplashScreen на 2 секунды, затем переходит на HomeShell.
class _AppStartup extends StatefulWidget {
  const _AppStartup();

  @override
  State<_AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<_AppStartup> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Минимальная задержка для показа логотипа (2 секунды).
    // В реальном приложении здесь будет загрузка данных / авторизация.
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  @override
  Widget build(BuildContext context) => const SplashScreen();
}
