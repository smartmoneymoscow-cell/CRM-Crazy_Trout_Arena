import '../data/demo_data.dart';
import '../models/client.dart';

/// Результат поиска клиента по QR-коду.
class QrLookupResult {
  final Client? client;
  final String? error;

  const QrLookupResult._({this.client, this.error});

  factory QrLookupResult.found(Client client) =>
      QrLookupResult._(client: client);

  factory QrLookupResult.notFound(String code) =>
      QrLookupResult._(error: 'Клиент с QR «$code» не найден');
}

/// Извлекает ID клиента из строки QR-кода.
///
/// Поддерживаемые форматы:
/// - `"client:<id>"` — стандартный формат (например, `"client:42"`)
/// - `"<id>"` — числовой ID (например, `"42"`)
///
/// Возвращает null, если не удалось извлечь числовой ID.
int? parseQrClientId(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final idStr = trimmed.contains(':') ? trimmed.split(':').last : trimmed;
  return int.tryParse(idStr);
}

/// Ищет клиента по QR-коду в переданном списке.
///
/// Алгоритм:
/// 1. Пытается извлечь числовой ID из QR → поиск по `Client.id`
/// 2. Если не найден — fallback: поиск по подстроке в имени или телефоне
QrLookupResult findClientByQr(String raw, {List<Client>? clients}) {
  final list = clients ?? kDemoClients;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return QrLookupResult.notFound(raw);

  // 1. Поиск по числовому ID
  final clientId = parseQrClientId(trimmed);
  if (clientId != null) {
    final match = list.where((c) => c.id == clientId);
    if (match.isNotEmpty) return QrLookupResult.found(match.first);
  }

  // 2. Fallback: поиск по имени / телефону
  final lower = trimmed.toLowerCase();
  final match = list.where(
    (c) => c.name.toLowerCase().contains(lower) || c.phone.contains(trimmed),
  );
  if (match.isNotEmpty) return QrLookupResult.found(match.first);

  return QrLookupResult.notFound(trimmed);
}
