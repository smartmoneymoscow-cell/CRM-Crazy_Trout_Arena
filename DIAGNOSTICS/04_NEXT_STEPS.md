# Следующие шаги для расследования

## 1. Проверить v1.3.11 (САМОЕ ВАЖНОЕ)
v1.3.11 = код v1.3.3 (точно рабочий) + текущий workflow.
- Если РАБОТАЕТ → проблема в изменениях v1.3.4, искать конкретно в каком файле
- Если КРАШИТСЯ → проблема в workflow/сборке, не в коде

## 2. Если проблема в коде v1.3.4:
Метод бинарного поиска:
- Вернуть ТОЛЬКО receipt_screen.dart к v1.3.3 → собрать → проверить
- Если работает → проблема в receipt_screen.dart
- Если крашится → вернуть demo_data.dart к v1.3.3 → проверить
- И так далее для каждого изменённого файла

## 3. Если проблема в workflow:
- Сравнить flutter create output локально vs CI
- Проверить flutter doctor в CI
- Проверить версию Dart/Gradle/AGP в CI
- Попробовать собрать APK локально из того же коммита

## 4. Получить crash log:
- adb logcat -d | grep -i "flutter\|fatal\|crash" | tail -50
- Или подключить Sentry когда будет рабочая версия

## 5. Проверить Android-specific:
- minSdkVersion в build.gradle
- targetSdkVersion
- Версия Gradle wrapper
- Версия AGP (Android Gradle Plugin)
- Наличие signing config

## 6. Контекст:
- Flutter 3.44.0 в CI
- Ubuntu latest (android), macOS latest (ios)
- split-per-abi (только arm64)
- flutter create генерирует build.gradle.kts (Kotlin DSL)
