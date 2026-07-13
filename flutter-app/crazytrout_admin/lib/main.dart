import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'screens/home_shell.dart';
import 'screens/splash_screen.dart';

// DSN и на Dart-уровне (для Dart-исключений/ANR), и продублирован в
// android/app/src/main/AndroidManifest.xml как meta-data (для нативных
// крашей ДО старта Flutter-движка — см. шаг workflow "Sentry native DSN").
const _sentryDsn =
    'https://497130229ebbe402ac2995fa888709cd@o4511723482382336.ingest.us.sentry.io/4511723747278848';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Фиксируем вертикальную ориентацию (портрет) — чек-касса не нужна в альбомной.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await SentryFlutter.init(
    (options) {
      options.dsn = _sentryDsn;
      options.environment = 'production';
      options.tracesSampleRate = 1.0;
      // Ловим и то, что происходит ДО первого кадра (важно именно для
      // краша "вылетает сразу при открытии").
      options.enableAutoSessionTracking = true;
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
