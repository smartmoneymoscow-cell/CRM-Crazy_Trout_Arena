# feat: iOS-эмулятор через Appetize.io

## Проблема

iOS-сборка `no-codesign` — нельзя установить на iPhone без provisioning profile и Apple Developer аккаунта. Для быстрого тестирования и демо нужен способ запустить IPA без подписи.

## Решение

Интегрировать [Appetize.io](https://appetize.io/) — облачный iOS/Android эмулятор в браузере.

### Что сделать

1. **Добавить секрет** `APPETIZE_API_TOKEN` в GitHub Settings → Secrets
2. **Добавить шаг** в workflow при релизе (`v*` тег):
   ```yaml
   - name: Upload IPA to Appetize.io
     run: |
       curl -X POST "https://api.appetize.io/v1/app/upload" \
         -H "Authorization: Bearer ${{ secrets.APPETIZE_API_TOKEN }}" \
         -F "file=@app-release.ipa" \
         -F "platform=ios" \
         -F "osVersion=18.0"
   ```
3. **Добавить embed-ссылку** в README после загрузки
4. Документация уже готова: `docs/APPETIZE.md`

### Ограничения

- `no-codesign` IPA может не запуститься — нужно проверить
- Бесплатный таринг: 30 мин/мес
- Bluetooth/камера не работают в эмуляторе

### Ссылки

- https://appetize.io
- https://docs.appetize.io
