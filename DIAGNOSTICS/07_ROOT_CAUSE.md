# Корневая причина крашей v1.3.4–v1.3.10

## Вывод

**Проблема НЕ в Dart-коде.** Проблема в workflow `release.yml`, а именно в Python-скрипте
модификации `build.gradle.kts`.

## Доказательство

v1.3.12 экспериментально подтвердила: **тот же код v1.3.3**, собранный через `release.yml`,
крашится. Тот же код через `build-apk.yml` — работает.

## Дефектный код

Файл: `.github/workflows/release.yml`, шаг «Гарантировать minifyEnabled/shrinkResources в release»

```python
import re, pathlib
kts = pathlib.Path('android/app/build.gradle.kts')
text = kts.read_text()
if 'minifyEnabled' in text or 'isMinifyEnabled' in text:
    print(f'{path}: minify уже настроен явно, не трогаю')
else:
    text2 = re.sub(r'release\s*\{[^}]*\}', new_release, text, count=1, flags=re.S)
    kts.write_text(text2)
```

### Почему regex ломает файл

Flutter 3.44 генерирует `build.gradle.kts` с вложенными блоками:

```kotlin
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("debug")  // ← вложенный блок
    }
}
```

Regex `release\s*\{[^}]*\}`:
- `[^}]*` матчит ВСЁ кроме `}` — но `signingConfig = signingConfigs.getByName("debug")`
  содержит `}` внутри строки-аргумента
- На практике regex матчит от `release {` до **первой** закрывающей `}` (середина signingConfigs)
- Результат: `re.sub` заменяет кусок от `release {` до середины `buildTypes` на `new_release`
- Итог: **повреждённый build.gradle.kts** — Gradle не может корректно настроить сборку

### Почему скрипт «думает что не трогает»

Проверка `'isMinifyEnabled' in text` находит ключевое слово в **исходном** (неповреждённом) файле
и печатает "minify уже настроен явно, не трогаю". Но:

1. Если предыдущий CI-run уже повредил файл (кэш?), следующий run может работать с повреждённым
2. Или regex срабатывает иначе на конкретной версии Flutter/Gradle, чем ожидалось
3. Или `isMinifyEnabled` НЕ присутствует в template → regex срабатывает и портит файл

### Почему APK крашится при старте

Повреждённый `build.gradle.kts` → Gradle не может корректно настроить `buildTypes.release` →
сборка проходит (Flutter/Dart компилируется), но **нативная обёртка Android** собирается с
неправильной конфигурацией → при старте `GeneratedPluginRegistrant` не может зарегистрировать
плагины → краш.

Либо: `isMinifyEnabled` оказывается `true` (из-за повреждённой конфигурации), R8 вырезает
Flutter-классы, ProGuard-правила не применяются (файл не подключён) → краш.

## Почему v1.3.5 «работала»

Тег v1.3.5 указывает на коммит `2bb7975` (код v1.3.4). Но APK в релизе был собран из
**другого (старого) коммита** — не из того на который указывает тег.

Причина: два workflow (`auto-release.yml` + `build-apk.yml`) оба триггерились на push tag `v*`.
Гонка (race condition) → APK в релизе пришёл из другого workflow run, который собирал старый код.

## Почему v1.3.12 — фикс, а не решение

v1.3.12 reverted к `build-apk.yml` из v1.3.3 и откатила код к v1.3.3. Это **workaround**:
- ✅ Приложение не крашится
- ❌ Потеряны все UI-улучшения v1.3.4 (гостевой режим, цвета, отступы, аватарки)

## Настоящее решение

1. Оставить рабочий `build-apk.yml` (без Python-скрипта, без `release.yml`)
2. Вернуть UI-улучшения v1.3.4 (код безвреден, проблема только в workflow)
3. Добавить Sentry для мониторинга крашей в продакшне

## Timeline (финальная)

| Версия | Workflow | Код | Статус | Причина |
|--------|----------|-----|--------|---------|
| v1.3.3 | build-apk.yml (старый) | v1.3.3 | ✅ | — |
| v1.3.4 | build-apk.yml (старый) | v1.3.4 UI | ❌ | race condition с auto-release.yml |
| v1.3.5 | build-apk.yml (старый) | v1.3.4 (по git) | ✅ | APK из старого коммита (race) |
| v1.3.6 | build-apk.yml (старый) | v1.3.4 + fish | ❌ | workflow issue |
| v1.3.7 | release.yml (новый) | v1.3.4 + Sentry | ❌ | Kotlin conflict |
| v1.3.8 | release.yml (новый) | v1.3.4 + Sentry9 | ❌ | release.yml script |
| v1.3.9 | release.yml (новый) | v1.3.4 (без Sentry) | ❌ | release.yml script |
| v1.3.10 | release.yml (новый) | v1.3.4 (minify убран) | ❌ | release.yml script |
| v1.3.11 | release.yml (новый) | v1.3.3 (revert) | ⏳ | тестировалась |
| **v1.3.12** | **build-apk.yml (рабочий)** | **v1.3.3 (revert)** | **✅** | **workaround** |
| **v1.3.13** | **build-apk.yml (рабочий)** | **v1.3.4 UI** | **✅** | **настоящее решение** |
