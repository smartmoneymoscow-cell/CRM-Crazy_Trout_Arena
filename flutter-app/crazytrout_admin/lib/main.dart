import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'screens/home_shell.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Фиксируем вертикальную ориентацию (портрет) — чек-касса не нужна в альбомной.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await SentryFlutter.init(
    (options) {
      // TODO: заменить на реальный DSN из https://sentry.io
      // Создайте проект Flutter → Settings → Client Keys (DSN)
      options.dsn = const String.fromEnvironment(
        'SENTRY_DSN',
        defaultValue: '',
      );
      // Среда (development / production)
      options.environment = const String.fromEnvironment(
        'SENTRY_ENV',
        defaultValue: 'production',
      );
      // Процент транзакций для performance monitoring (1.0 = 100%)
      options.tracesSampleRate = 1.0;
      // Не отправлять в debug-режиме
      options.beforeSend = (event, hint) {
        // Если DSN пустой — не отправляем
        if (event.sdk?.name == null) return null;
        return event;
      };
    },
    appRunner: () => runApp(const CrazyTroutAdminApp()),
  );
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
