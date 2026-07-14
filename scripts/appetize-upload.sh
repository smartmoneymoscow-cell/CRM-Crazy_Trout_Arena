#!/bin/bash
# Загрузка APK/IPA в Appetize.io
# Использование: ./scripts/appetize-upload.sh <file> [platform] [osVersion]
#
# Примеры:
#   ./scripts/appetize-upload.sh app-release.apk android 15.0
#   ./scripts/appetize-upload.sh app-release.ipa ios 18.0

set -e

FILE="${1:?Укажи файл: app-release.apk или app-release.ipa}"
PLATFORM="${2:-android}"
OS_VERSION="${3:-15.0}"
TOKEN="${APPETIZE_API_TOKEN:?Установи APPETIZE_API_TOKEN}"

echo "📤 Загружаю $FILE в Appetize.io..."
echo "   Платформа: $PLATFORM"
echo "   OS: $OS_VERSION"

RESPONSE=$(curl -s -X POST "https://api.appetize.io/v1/app/upload" \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@$FILE" \
  -F "platform=$PLATFORM" \
  -F "osVersion=$OS_VERSION" \
  -F "note=Crazy Trout Arena — $(date +%Y-%m-%d)")

echo "✅ Ответ:"
echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"

# Извлекаем publicKey и URL
PUBLIC_KEY=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('publicKey',''))" 2>/dev/null)

if [ -n "$PUBLIC_KEY" ]; then
  echo ""
  echo "🔗 Embed-ссылка:"
  echo "   https://appetize.io/embed/$PUBLIC_KEY"
  echo ""
  echo "📱 Прямая ссылка:"
  echo "   https://appetize.io/app/$PUBLIC_KEY"
fi
