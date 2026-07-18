// === Store — состояние приложения + демо-данные ===

import { tg } from './telegram.js';
import { events } from './events.js';

// --- Демо-данные (идентичны Flutter-приложению) ---

const TARIFFS = [
  { id: 'standard',  label: 'Стандарт',  price: 750 },
  { id: 'guest',     label: 'Гостевой',  price: 500 },
  { id: 'pensioner', label: 'Пенсионер', price: 0 },
];

const FISH_BREEDS = [
  { id: 'sturgeon', label: 'Осётр',   pricePerKg: 1200, emoji: '🐟' },
  { id: 'carp',     label: 'Карп',    pricePerKg: 600,  emoji: '🐠' },
  { id: 'amur',     label: 'Амур',    pricePerKg: 800,  emoji: '🐡' },
  { id: 'tench',    label: 'Линь',    pricePerKg: 900,  emoji: '🎣' },
  { id: 'trout',    label: 'Форель',  pricePerKg: 1500, emoji: '🍣' },
];

const DEMO_CLIENTS = [
  { id: 100, name: 'Уэйд Джереми',  phone: '+7 999 123-45-67', tariff: 'standard',  avatar: null, level: 'premium',  visits: 42, totalSpent: 31500 },
  { id: 101, name: 'Иванов Пётр',   phone: '+7 999 234-56-78', tariff: 'standard',  avatar: null, level: 'standard', visits: 15, totalSpent: 11250 },
  { id: 102, name: 'Смирнова Анна', phone: '+7 999 345-67-89', tariff: 'pensioner', avatar: null, level: 'basic',    visits: 8,  totalSpent: 0 },
  { id: 103, name: 'Козлов Дмитрий',phone: '+7 999 456-78-90', tariff: 'guest',     avatar: null, level: 'basic',    visits: 1,  totalSpent: 500 },
  { id: 104, name: 'Петрова Мария', phone: '+7 999 567-89-01', tariff: 'standard',  avatar: null, level: 'premium',  visits: 28, totalSpent: 21000 },
];

const DEMO_RECEIPTS = [
  { id: '001', clientId: 100, date: '2026-07-18 14:30', tariff: 'standard', tariffPrice: 750, catches: [{ breed: 'sturgeon', kg: 2, grams: 300, pricePerKg: 1200, sum: 2760 }], total: 3510, paymentMethod: 'card', fiscal: true },
  { id: '002', clientId: 101, date: '2026-07-18 11:00', tariff: 'standard', tariffPrice: 750, catches: [{ breed: 'carp', kg: 1, grams: 500, pricePerKg: 600, sum: 900 }], total: 1650, paymentMethod: 'cash', fiscal: true },
  { id: '003', clientId: 104, date: '2026-07-17 16:45', tariff: 'standard', tariffPrice: 750, catches: [{ breed: 'trout', kg: 0, grams: 800, pricePerKg: 1500, sum: 1200 }], total: 1950, paymentMethod: 'card', fiscal: false },
  { id: '004', clientId: 102, date: '2026-07-17 09:15', tariff: 'pensioner', tariffPrice: 0, catches: [], total: 0, paymentMethod: 'account', fiscal: false },
  { id: '005', clientId: 100, date: '2026-07-16 13:00', tariff: 'standard', tariffPrice: 750, catches: [{ breed: 'amur', kg: 3, grams: 0, pricePerKg: 800, sum: 2400 }], total: 3150, paymentMethod: 'cash', fiscal: true },
];

const SECTORS = Array.from({ length: 16 }, (_, i) => ({
  id: i + 1,
  occupied: [2, 5, 7, 10, 14].includes(i + 1),
  clientId: [2, 5, 7, 10, 14].includes(i + 1) ? DEMO_CLIENTS[[0, 0, 1, 0, 2, 3, 0, 4, 0, 0, 0, 0, 0, 0, 0][i]]?.id : null,
}));

// --- Store ---

class Store {
  constructor() {
    this.tariffs = TARIFFS;
    this.fishBreeds = FISH_BREEDS;
    this.clients = [...DEMO_CLIENTS];
    this.receipts = [...DEMO_RECEIPTS];
    this.sectors = [...SECTORS];
    
    this.currentClient = null;
    this.currentReceipt = null;
  }

  // --- Клиенты ---
  
  findClient(query) {
    const q = query.toLowerCase().trim();
    if (!q) return null;
    return this.clients.find(c =>
      c.name.toLowerCase().includes(q) ||
      c.phone.replace(/\D/g, '').includes(q.replace(/\D/g, ''))
    ) || null;
  }

  getClientById(id) {
    return this.clients.find(c => c.id === Number(id)) || null;
  }

  getClientInitials(client) {
    if (!client) return '?';
    const parts = client.name.split(' ');
    return parts.length >= 2
      ? (parts[0][0] + parts[1][0]).toUpperCase()
      : (parts[0][0] || '?').toUpperCase();
  }

  getLevelBadge(level) {
    const badges = { premium: '🥇 Премиум', standard: '🥈 Стандарт', basic: '🥉 Базовый' };
    return badges[level] || badges.basic;
  }

  // --- Чеки ---
  
  getReceiptsByClient(clientId) {
    return this.receipts.filter(r => r.clientId === clientId);
  }

  getClientLTV(clientId) {
    return this.getReceiptsByClient(clientId).reduce((sum, r) => sum + r.total, 0);
  }

  getClientAvgCatch(clientId) {
    const receipts = this.getReceiptsByClient(clientId);
    if (!receipts.length) return { pieces: 0, kg: 0 };
    const totalPieces = receipts.reduce((sum, r) => sum + r.catches.length, 0);
    const totalKg = receipts.reduce((sum, r) =>
      sum + r.catches.reduce((s, c) => s + c.kg + c.grams / 1000, 0), 0);
    return {
      pieces: (totalPieces / receipts.length).toFixed(1),
      kg: (totalKg / receipts.length).toFixed(1),
    };
  }

  // --- Статистика ---
  
  getStats() {
    const receipts = this.receipts;
    const totalRevenue = receipts.reduce((sum, r) => sum + r.total, 0);
    const avgCheck = receipts.length ? Math.round(totalRevenue / receipts.length) : 0;
    const uniqueClients = new Set(receipts.map(r => r.clientId)).size;
    
    return { totalRevenue, avgCheck, uniqueClients, totalReceipts: receipts.length };
  }
}

export const store = new Store();
export { TARIFFS, FISH_BREEDS };
