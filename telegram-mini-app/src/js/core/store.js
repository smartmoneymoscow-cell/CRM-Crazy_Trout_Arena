// === Store — состояние приложения + демо-данные (точь-в-точь Flutter) ===
import { tg } from './telegram.js';
import { events } from './events.js';

// ─── Тарифы (demo_data.dart kTariffs) ───
const TARIFFS = [
  { id: 'standard',  label: 'Стандарт',  price: 750 },
  { id: 'guest',     label: 'Гостевой',  price: 500 },
  { id: 'pensioner', label: 'Пенсионер', price: 0 },
];

// ─── Породы рыбы (demo_data.dart kSpecies, kSpeciesPrice, kSpeciesImage) ───
const FISH_BREEDS = [
  { id: 'sturgeon', label: 'Осётр',   pricePerKg: 1890, emoji: '🐟', image: 'src/assets/fish/sturgeon.png',   imageHeight: 32 },
  { id: 'carp',     label: 'Карп',    pricePerKg: 590,  emoji: '🐠', image: 'src/assets/fish/carp.png',       imageHeight: 24 },
  { id: 'amur',     label: 'Амур',    pricePerKg: 750,  emoji: '🐡', image: 'src/assets/fish/grass_carp.png', imageHeight: 28 },
  { id: 'tench',    label: 'Линь',    pricePerKg: 690,  emoji: '🎣', image: 'src/assets/fish/tench.png',      imageHeight: 22 },
  { id: 'trout',    label: 'Форель',  pricePerKg: 1200, emoji: '🍣', image: 'src/assets/fish/trout.png',      imageHeight: 24 },
];

// ─── Демо-клиенты (demo_data.dart kDemoClients) ───
const DEMO_CLIENTS = [
  { id: 1,   name: 'Иван Иванов',     phone: '+7 925 123-45-67', tariff: 'standard',  level: 'premium',  visits: 42, totalSpent: 31500, points: 850, pointsNext: 1000, avatarAsset: 'src/assets/avatars/avatar_1.jpeg' },
  { id: 2,   name: 'Алексей Кошкин',  phone: '+7 916 555-22-11', tariff: 'standard',  level: 'standard', visits: 15, totalSpent: 11250, points: 320, pointsNext: 500,  avatarAsset: 'src/assets/avatars/avatar_2.jpeg' },
  { id: 3,   name: 'Сергей Петров',   phone: '+7 903 777-44-33', tariff: 'standard',  level: 'premium',  visits: 28, totalSpent: 21000, points: 700, pointsNext: 1000, avatarAsset: 'src/assets/avatars/avatar_3.jpeg' },
  { id: 4,   name: 'Нина Крюкова',    phone: '+7 912 666-33-44', tariff: 'pensioner', level: 'basic',    visits: 8,  totalSpent: 0,     points: 50,  pointsNext: 200,  avatarAsset: null },
  { id: 5,   name: 'Дмитрий Лагута',  phone: '+7 985 111-22-33', tariff: 'standard',  level: 'standard', visits: 12, totalSpent: 9000,  points: 280, pointsNext: 500,  avatarAsset: 'src/assets/avatars/avatar_5.jpeg' },
  { id: 6,   name: 'Михаил Орлов',    phone: '+7 962 888-99-00', tariff: 'pensioner', level: 'basic',    visits: 5,  totalSpent: 0,     points: 30,  pointsNext: 200,  avatarAsset: 'src/assets/avatars/avatar_6.jpeg' },
  { id: 7,   name: 'Олег Сидоров',    phone: '+7 905 222-77-66', tariff: 'standard',  level: 'standard', visits: 18, totalSpent: 13500, points: 400, pointsNext: 500,  avatarAsset: 'src/assets/avatars/avatar_7.jpeg' },
  { id: 8,   name: 'Виктор Щукин',    phone: '+7 910 444-55-66', tariff: 'standard',  level: 'premium',  visits: 35, totalSpent: 26250, points: 780, pointsNext: 1000, avatarAsset: 'src/assets/avatars/avatar_8.jpeg' },
  { id: 100, name: 'Уэйд Джереми',    phone: '+7 999 000-00-00', tariff: 'standard',  level: 'premium',  visits: 56, totalSpent: 42000, points: 950, pointsNext: 1000, avatarAsset: 'src/assets/avatars/avatar_100.jpeg' },
];

// ─── Демо-чеки ───
const DEMO_RECEIPTS = [
  { id: '001', clientId: 100, date: '2026-07-18 14:30', tariff: 'standard', tariffLabel: 'Стандарт', tariffPrice: 750, catches: [{ breed: 'sturgeon', label: 'Осётр', kg: 2, grams: 300, pricePerKg: 1890, sum: 4347 }], total: 5097, paymentMethod: 'card', paymentLabel: 'Картой', fiscal: true },
  { id: '002', clientId: 1,   date: '2026-07-18 11:00', tariff: 'standard', tariffLabel: 'Стандарт', tariffPrice: 750, catches: [{ breed: 'carp', label: 'Карп', kg: 1, grams: 500, pricePerKg: 590, sum: 885 }], total: 1635, paymentMethod: 'cash', paymentLabel: 'Наличными', fiscal: true },
  { id: '003', clientId: 8,   date: '2026-07-17 16:45', tariff: 'standard', tariffLabel: 'Стандарт', tariffPrice: 750, catches: [{ breed: 'trout', label: 'Форель', kg: 0, grams: 800, pricePerKg: 1200, sum: 960 }], total: 1710, paymentMethod: 'card', paymentLabel: 'Картой', fiscal: false },
  { id: '004', clientId: 4,   date: '2026-07-17 09:15', tariff: 'pensioner', tariffLabel: 'Пенсионер', tariffPrice: 0, catches: [], total: 0, paymentMethod: 'account', paymentLabel: 'Счет заведения', fiscal: false },
  { id: '005', clientId: 100, date: '2026-07-16 13:00', tariff: 'standard', tariffLabel: 'Стандарт', tariffPrice: 750, catches: [{ breed: 'amur', label: 'Амур', kg: 3, grams: 0, pricePerKg: 750, sum: 2250 }], total: 3000, paymentMethod: 'cash', paymentLabel: 'Наличными', fiscal: true },
  { id: '006', clientId: 3,   date: '2026-07-15 10:00', tariff: 'standard', tariffLabel: 'Стандарт', tariffPrice: 750, catches: [{ breed: 'sturgeon', label: 'Осётр', kg: 1, grams: 200, pricePerKg: 1890, sum: 2268 }], total: 3018, paymentMethod: 'card', paymentLabel: 'Картой', fiscal: true },
  { id: '007', clientId: 5,   date: '2026-07-14 15:30', tariff: 'standard', tariffLabel: 'Стандарт', tariffPrice: 750, catches: [{ breed: 'tench', label: 'Линь', kg: 2, grams: 100, pricePerKg: 690, sum: 1449 }], total: 2199, paymentMethod: 'cash', paymentLabel: 'Наличными', fiscal: true },
  { id: '008', clientId: 100, date: '2026-07-13 12:00', tariff: 'standard', tariffLabel: 'Стандарт', tariffPrice: 750, catches: [{ breed: 'trout', label: 'Форель', kg: 1, grams: 500, pricePerKg: 1200, sum: 1800 }], total: 2550, paymentMethod: 'card', paymentLabel: 'Картой', fiscal: true },
];

// ─── Секторы (16 штук, как Flutter PondMapScreen) ───
const SECTORS = Array.from({ length: 16 }, (_, i) => ({
  id: i + 1,
  occupied: [2, 5, 7, 10, 14].includes(i + 1),
  clientId: [null, 1, null, null, 100, null, null, 8, null, null, 3, null, null, null, 5, null][i],
}));

// ─── Store ───
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

  findClient(query) {
    const q = query.toLowerCase().trim();
    if (!q) return null;
    return this.clients.find(c =>
      c.name.toLowerCase().includes(q) ||
      c.phone.replace(/\D/g, '').includes(q.replace(/\D/g, ''))
    ) || null;
  }

  searchClients(query) {
    const q = query.toLowerCase().trim();
    if (!q) return [];
    return this.clients.filter(c =>
      c.name.toLowerCase().includes(q) || c.phone.includes(q)
    ).sort((a, b) => {
      const an = a.name.toLowerCase();
      const bn = b.name.toLowerCase();
      const aStarts = an.startsWith(q) ? 0 : 1;
      const bStarts = bn.startsWith(q) ? 0 : 1;
      if (aStarts !== bStarts) return aStarts - bStarts;
      return an.compareTo?.(bn) || an.localeCompare(bn);
    });
  }

  getClientById(id) { return this.clients.find(c => c.id === Number(id)) || null; }

  getClientInitials(client) {
    if (!client) return '?';
    const parts = client.name.split(' ');
    return parts.length >= 2
      ? (parts[0][0] + parts[1][0]).toUpperCase()
      : (parts[0][0] || '?').toUpperCase();
  }

  renderAvatar(client, size = 40) {
    if (!client) return `<div class="client-avatar" style="width:${size}px;height:${size}px;">?</div>`;
    if (client.avatarAsset) {
      return `<div class="client-avatar" style="width:${size}px;height:${size}px;"><img src="${client.avatarAsset}" alt="${client.name}" style="width:100%;height:100%;object-fit:cover;border-radius:50%;"></div>`;
    }
    return `<div class="client-avatar" style="width:${size}px;height:${size}px;">${this.getClientInitials(client)}</div>`;
  }

  getLevelBadge(level) {
    const badges = {
      premium:  { letter: 'П', label: 'Премиум',  cssClass: 'badge-premium' },
      standard: { letter: 'С', label: 'Стандарт', cssClass: 'badge-standard' },
      basic:    { letter: 'Б', label: 'Базовый',  cssClass: 'badge-basic' },
    };
    return badges[level] || badges.basic;
  }

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

  getStats() {
    const receipts = this.receipts;
    const totalRevenue = receipts.reduce((sum, r) => sum + r.total, 0);
    const avgCheck = receipts.length ? Math.round(totalRevenue / receipts.length) : 0;
    const uniqueClients = new Set(receipts.map(r => r.clientId)).size;
    return { totalRevenue, avgCheck, uniqueClients, totalReceipts: receipts.length };
  }

  formatMoney(v) {
    const s = Math.round(v).toString();
    let buf = '';
    for (let i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 === 0) buf += ' ';
      buf += s[i];
    }
    return buf;
  }

  formatDate(d) {
    const two = n => String(n).padStart(2, '0');
    return `${two(d.getDate())}.${two(d.getMonth() + 1)}.${d.getFullYear()}`;
  }
}

export const store = new Store();
export { TARIFFS, FISH_BREEDS };
