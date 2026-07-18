// === Storage Service ===
// Обёртка: Telegram CloudStorage → localStorage fallback

import { tg } from '../core/telegram.js';

class StorageService {
  // --- Сохранить ---
  
  async set(key, value) {
    const serialized = typeof value === 'string' ? value : JSON.stringify(value);
    return tg.setStorage(key, serialized);
  }

  // --- Получить ---
  
  async get(key, defaultValue = null) {
    const raw = await tg.getStorage(key);
    if (raw === null || raw === undefined) return defaultValue;
    
    try {
      return JSON.parse(raw);
    } catch {
      return raw;
    }
  }

  // --- Удалить ---
  
  async remove(key) {
    return tg.removeStorage(key);
  }

  // --- Получить все ключи ---
  
  async keys() {
    return new Promise((resolve) => {
      if (!tg.isAvailable) {
        resolve(Object.keys(localStorage));
        return;
      }
      tg.webapp.CloudStorage.getKeys((err, keys) => {
        resolve(err ? [] : keys);
      });
    });
  }

  // --- Клиент-specific helpers ---
  
  async saveLastClient(clientId) {
    return this.set('last_client_id', clientId);
  }

  async getLastClient() {
    return this.get('last_client_id');
  }

  async savePrinterConfig(config) {
    return this.set('printer_config', config);
  }

  async getPrinterConfig() {
    return this.get('printer_config', {});
  }

  async saveReceiptDraft(draft) {
    return this.set('receipt_draft', draft);
  }

  async getReceiptDraft() {
    return this.get('receipt_draft');
  }

  async clearReceiptDraft() {
    return this.remove('receipt_draft');
  }
}

export const storage = new StorageService();
