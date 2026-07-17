# Contributing — Crazy Trout Arena CRM

## Структура CI/CD

| Workflow | Триггер | Что делает |
|----------|---------|------------|
| `build.yml` | push в `main` | Валидация ассетов → Сборка APK + IPA → Артефакты (без релиза) |
| `release.yml` | push тега `v*` | Валидация ассетов → Сборка APK + IPA → GitHub Release |
| `pr-checks.yml` | PR в `main` | `flutter analyze` + `flutter test` |

**Правило:** один workflow = один триггер. Никогда не создавать два workflow на одно событие.

---

## Архитектура: общие модули

Цветовые константы, модели и статистика клиентов вынесены в общие файлы.
**Категорически запрещено** дублировать их в экранах/виджетах.

| Файл | Содержимое |
|------|------------|
| `lib/theme/app_theme.dart` | Цвета (`kInk`, `kPaper`, ...), `LevelKey`, `LevelStyle`, `BestCatch` |
| `lib/data/pond_stats.dart` | `PondStats`, `FullClient`, `kPondStatsById`, `kFullClients` |
| `lib/utils/format.dart` | `money()` и другие форматтеры |

Если вам нужен цвет/модель — импортируйте, не копируйте.

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

## Процесс релиза

### Правила
1. **Релиз = тег + changelog.** Никаких ручных созданий Release через UI GitHub.
2. **Changelog генерируется автоматически** из коммитов (feat/fix/other) при пуше тега.
3. **APK прикрепляется к каждому релизу.** Если IPA не собрался — релиз всё равно выходит.
4. **Не создавать теги чаще 1 раза в час.** Серийные hotfix-теги (v1.3.90 → v1.3.91 за 2 минуты) — признак отсутствия тестирования.
5. **Перед тегом:** `flutter test` + `flutter analyze` должны пройти локально.

### Формат коммитов
```
feat: описание фичи
fix: описание багфикса
ci: изменения в CI/CD
docs: обновление документации
refactor: рефакторинг без изменения поведения
```

Префикс `feat:` / `fix:` автоматически попадает в changelog релиза.

---

## Теги

- Теги не должны перемещаться (force-push)
- Каждый тег = один коммит = один Release
- Формат: `vX.Y.Z` (semver)

---

## Защита от регрессий

### Правило 1: Не удаляй проверочную логику без понимания контекста

Перед удалением `if`, `ConstrainedBox`, `maxHeight`, `showAbove` или любых ограничений:
1. `git log --follow -p -- <файл>` по затронутым строкам
2. Если видишь серию фиксов (`fix: ...`) — не трогай без объяснения в коммите
3. В коммите указывай **почему** логика больше не нужна, а не только **что** удалено

**Пример нарушения:**
```
fix: dropdown — просто вниз, без showAbove, без scroll, без constraints
```
Этот коммит удалил `showAbove` и `ConstrainedBox`, которые решали реальные баги
(перекрытие нижнего меню). Без объяснения — следующий разработчик не поймёт,
что это регрессия.

**Пример корректного коммита:**
```
fix: dropdown — убран showAbove

Причина: CompositedTransformFollower + ConstrainedBox решают задачу
без showAbove. showAbove добавлял сложность и мигал при открытии.
ConstrainedBox оставлен — он защищает от перекрытия навбара.
```

### Правило 2: Критичные константы — в отдельном файле с тестами

Константы, которые решают баги (gap, maxHeight, navHeight), должны:
- Жить в `pond_map_filter_config.dart` (или аналоге)
- Иметь unit-тесты в `test/screens/pond_map_filter_test.dart`
- Иметь комментарий с ссылкой на коммит-фикс

Если вы изменяете константу и тест падает — вы ломаете исправленный баг.
Сначала поймите почему значение было таким, потом меняйте.

### Правило 3: PR-checks не пропускают сломанные тесты

`flutter test` — обязательный шаг в `pr-checks.yml`. Если тест падает — PR не мержится.

### Правило 4: Тесты на UI-компоненты с позиционированием

Виджеты, которые используют `Overlay`, `CompositedTransformFollower`,
`Positioned` или абсолютное позиционирование, должны иметь widget-тесты
проверяющие:
- Открытие/закрытие
- Выбор варианта
- Отсутствие перекрытия критичных элементов (нижнее меню, AppBar)
