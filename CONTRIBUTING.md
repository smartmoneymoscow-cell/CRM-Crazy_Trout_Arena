# Contributing — Crazy Trout Arena CRM

## Структура CI/CD

| Workflow | Триггер | Что делает |
|----------|---------|------------|
| `build.yml` | push в `main` | Валидация ассетов → Сборка APK + IPA → Артефакты (без релиза) |
| `release.yml` | push тега `v*` | Валидация ассетов → Сборка APK + IPA → GitHub Release |
| `pr-checks.yml` | PR в `main` | `flutter analyze` + `flutter test` |

**Правило:** один workflow = один триггер. Никогда не создавать два workflow на одно событие.

---

## Checklist перед релизом

Перед `git tag vX.Y.Z && git push origin vX.Y.Z`:

```bash
# 1. Все ассеты в git
cd flutter-app/crazytrout_admin
git ls-files assets/ | wc -l                    # должно быть > 0
grep -roh "assets/[^'\"]*" lib/ | sort -u       # все ссылки из кода
# Каждая ссылка должна对应的 файл существовать

# 2. pubspec.yaml — все ассеты зарегистрированы
# Каждый файл из assets/ должен быть в pubspec.yaml

# 3. Тесты проходят
flutter test

# 4. Сборка не крашится
flutter build apk --release --split-per-abi

# 5. ProGuard-правила в файле, а не в CI
cat android/app/proguard-rules.pro
# Должен содержать keep-rules для Flutter + все плагины
```

---

## ProGuard/R8 правила

**Единый источник:** `flutter-app/crazytrout_admin/android/app/proguard-rules.pro`

При добавлении нового плагина с нативным кодом (Java/Kotlin/Swift/Objective-C):
1. Добавить `-keep class <package>.** { *; }` в `proguard-rules.pro`
2. Не инжектировать правила через CI — только в файле

---

## Ассеты (фото, шрифты, иконки)

1. Положить файл в `assets/<категория>/`
2. Зарегистрировать в `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/fish/sturgeon.png
   ```
3. Закоммитить и запушить **до** создания тега

CI автоматически проверит что все `AssetImage('assets/...')` из Dart-кода ссылаются на существующие файлы.

---

## Workflow файлы

### build.yml — сборка при пуше в main
- Валидация ассетов (Dart-код → файлы)
- Валидация pubspec.yaml (файлы → регистрация)
- Сборка APK + IPA
- **Не создаёт GitHub Release**

### release.yml — сборка + релиз при теге
- Те же шаги что и build.yml
- Плюс: `softprops/action-gh-release` для создания Release
- Один job `release` ждёт оба билда (`needs: [build-android, build-ios]`)
- Артефакты скачиваются из **своего** workflow run (не из другого)

### pr-checks.yml — проверки на PR
- `flutter analyze --fatal-infos`
- `flutter test`
- concurrency: отменяет предыдущие запуски для того же PR

---

## Теги

- Теги не должны перемещаться (force-push)
- Каждый тег = один коммит = один Release
- Формат: `vX.Y.Z` (semver)
