# Текущее состояние workflow

## release.yml (теги v*)
1. validate-assets — проверяет что все файлы в assets/ зарегистрированы в pubspec.yaml
2. build-android — flutter create → permissions → pub get → flutter_launcher_icons → flutter test → flutter build apk --release --split-per-abi
3. build-ios — flutter create → pub get → permissions → ios 13.0 → flutter_launcher_icons → flutter test → flutter build ios --release --no-codesign
4. release — скачивает артефакты → softprops/action-gh-release

## Что УБРАНО из workflow:
- Шаг ProGuard-правил (инжектировал keep-rules через cat >>)
- Шаг minifyEnabled (Python-скрипт который НЕ работал корректно)

## Что ДОБАВЛЕНО в workflow:
- validate-assets job
- ProGuard rules в репо (статический файл android/app/proguard-rules.pro)

## Проблема с workflow:
Python-скрипт для minify проверял:
  if 'minifyEnabled' in text or 'isMinifyEnabled' in text:
      print('minify уже настроен явно, не трогаю')
flutter 3.44 ГЕНЕРИРУЕТ build.gradle.kts с `isMinifyEnabled = false`.
Скрипт находил ключевое слово и ПРОПУСКАЛ модификацию.
Результат: minification НЕ включался, НО скрипт думал что настроено.

## Версии:
- v1.3.3: workflow build-apk.yml (старый), minify НЕ включён (skipped)
- v1.3.5: workflow build-apk.yml (старый), minify НЕ включён (skipped)
- v1.3.10: workflow release.yml (новый), minify шаг УДАЛЁН
- v1.3.11: workflow release.yml (новый), minify шаг УДАЛЁН, код reverted к v1.3.3
