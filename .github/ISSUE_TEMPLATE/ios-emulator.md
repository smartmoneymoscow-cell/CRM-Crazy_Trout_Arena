---
name: "iOS-эмулятор в браузере"
about: "Интеграция Appetize.io для запуска iOS-сборки в браузере"
title: "feat: iOS-эмулятор через Appetize.io"
labels: enhancement, ios
assignees: ''
---

## Описание

Добавить автоматическую загрузку iOS-сборки (IPA) в Appetize.io при каждом релизе, чтобы можно было протестировать приложение в iOS-эмуляторе прямо в браузере.

## Зачем

- Текущая iOS-сборка без кодирования (`no-codesign`) — нельзя установить на устройство без provisioning profile
- Appetize.io позволяет запустить IPA в браузере без подписи
- Удобно для демо и быстрого тестирования

## План

### 1. Workflow: автоматическая загрузка IPA в Appetize.io

Добавить шаг в `.github/workflows/build-apk.yml` (или создать отдельный `appetize.yml`):

```yaml
- name: Upload IPA to Appetize.io
  if: startsWith(github.ref, 'refs/tags/v')
  run: |
    curl -X POST "https://api.appetize.io/v1/app/upload" \
      -H "Authorization: Bearer ${{ secrets.APPETIZE_API_TOKEN }}" \
      -F "file=@app-release.ipa" \
      -F "platform=ios" \
      -F "osVersion=18.0" \
      -F "note=Crazy Trout Arena ${{ github.ref_name }}"
```

### 2. GitHub Secret

Добавить секрет `APPETIZE_API_TOKEN` в настройки репозитория:
- Settings → Secrets and variables → Actions → New repository secret
- Имя: `APPETIZE_API_TOKEN`
- Значение: токен из Appetize.io → Account → API Keys

### 3. Обновить README

После загрузки Appetize вернёт `publicKey`. Добавить embed-ссылку в README:

```html
https://appetize.io/embed/<publicKey>?device=iphone15pro&osVersion=18.0
```

### 4. Ограничения

- [ ] Проверить, работает ли `no-codesign` IPA на Appetize (может потребоваться provisioning profile)
- [ ] Бесплатный таринг: 30 мин/мес — хватит на несколько запусков за релиз
- [ ] Bluetooth и камера не работают в эмуляторе

## Acceptance Criteria

- [ ] При создании тега `v*` IPA автоматически загружается в Appetize.io
- [ ] В README есть ссылка на эмулятор
- [ ] В `docs/APPETIZE.md` есть полная инструкция по API

## Ссылки

- Appetize.io: https://appetize.io
- Документация API: https://docs.appetize.io
- Текущая инструкция: [docs/APPETIZE.md](../docs/APPETIZE.md)
