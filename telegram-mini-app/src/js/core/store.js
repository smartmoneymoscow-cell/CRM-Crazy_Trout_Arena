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

// ─── Демо-клиенты (точь-в-точь Flutter pond_stats.dart kPondStatsById) ───
const DEMO_CLIENTS = [
  { id: 1,   name: 'Иван Иванов',     phone: '+7 925 123-45-67', email: 'ivanov@mail.ru',      tariff: 'standard',  level: 'premium',  color: '#E89829', visits: 42, totalSpent: 31500, ltvK: 120,  points: 1280, pointsNext: 1500, fish: 96,  totalWeight: 215, firstVisit: '14.03.2023', lastVisit: '15.07.2026', currentSector: 7,  bestCatch: { species: 'Осётр', weight: '6.2 кг', sector: 7, date: '02.07.2026' }, avatarAsset: 'src/assets/avatars/avatar_1.jpeg' },
  { id: 2,   name: 'Алексей Кошкин',  phone: '+7 916 555-22-11', email: 'koshkin@mail.ru',     tariff: 'standard',  level: 'standard', color: '#3FA66B', visits: 18, totalSpent: 13500, ltvK: 54,   points: 640,  pointsNext: 1000, fish: 31,  totalWeight: 78,  firstVisit: '02.08.2024', lastVisit: '15.07.2026', currentSector: 4,  bestCatch: { species: 'Карп', weight: '3.4 кг', sector: 4, date: '28.06.2026' }, avatarAsset: 'src/assets/avatars/avatar_2.jpeg' },
  { id: 3,   name: 'Сергей Петров',   phone: '+7 903 777-44-33', email: 'petrov@mail.ru',      tariff: 'standard',  level: 'premium',  color: '#2A6A7E', visits: 55, totalSpent: 41250, ltvK: 1200, points: 1410, pointsNext: 1500, fish: 122, totalWeight: 289, firstVisit: '27.01.2022', lastVisit: '14.07.2026', currentSector: 2,  bestCatch: { species: 'Осётр', weight: '7.8 кг', sector: 2, date: '19.06.2026' }, avatarAsset: 'src/assets/avatars/avatar_3.jpeg' },
  { id: 4,   name: 'Нина Крюкова',    phone: '+7 912 666-33-44', email: 'kryukova@mail.ru',    tariff: 'pensioner', level: 'basic',    color: '#9C5A3C', visits: 1,  totalSpent: 0,     ltvK: 2,    points: 30,  pointsNext: 500,  fish: 3,   totalWeight: 5,   firstVisit: '14.07.2026', lastVisit: '14.07.2026', currentSector: null, bestCatch: { species: 'Линь', weight: '1.1 кг', sector: 9, date: '14.07.2026' }, avatarAsset: null },
  { id: 5,   name: 'Дмитрий Лагута',  phone: '+7 985 111-22-33', email: 'laguta@mail.ru',      tariff: 'standard',  level: 'standard', color: '#886F11', visits: 21, totalSpent: 15750, ltvK: 68,   points: 780,  pointsNext: 1000, fish: 40,  totalWeight: 103, firstVisit: '11.11.2023', lastVisit: '13.07.2026', currentSector: 5,  bestCatch: { species: 'Амур', weight: '4.9 кг', sector: 5, date: '30.06.2026' }, avatarAsset: 'src/assets/avatars/avatar_5.jpeg' },
  { id: 6,   name: 'Михаил Орлов',    phone: '+7 962 888-99-00', email: 'orlov@mail.ru',       tariff: 'pensioner', level: 'premium',  color: '#B8862E', visits: 68, totalSpent: 51000, ltvK: 2400, points: 1500, pointsNext: 1500, fish: 150, totalWeight: 365, firstVisit: '03.06.2021', lastVisit: '15.07.2026', currentSector: 1,  bestCatch: { species: 'Осётр', weight: '8.4 кг', sector: 1, date: '24.06.2026' }, avatarAsset: 'src/assets/avatars/avatar_6.jpeg' },
  { id: 7,   name: 'Олег Сидоров',    phone: '+7 905 222-77-66', email: 'sidorov@mail.ru',     tariff: 'standard',  level: 'basic',    color: '#6B7280', visits: 7,  totalSpent: 5250,  ltvK: 15,   points: 260,  pointsNext: 500,  fish: 12,  totalWeight: 22,  firstVisit: '09.02.2026', lastVisit: '10.07.2026', currentSector: 10, bestCatch: { species: 'Линь', weight: '1.6 кг', sector: 10, date: '11.06.2026' }, avatarAsset: 'src/assets/avatars/avatar_7.jpeg' },
  { id: 8,   name: 'Виктор Щукин',    phone: '+7 910 444-55-66', email: 'shchukin@mail.ru',    tariff: 'standard',  level: 'standard', color: '#9C5A3C', visits: 14, totalSpent: 10500, ltvK: 46,   points: 520,  pointsNext: 1000, fish: 27,  totalWeight: 61,  firstVisit: '18.01.2025', lastVisit: '12.07.2026', currentSector: 8,  bestCatch: { species: 'Щука', weight: '4.1 кг', sector: 8, date: '15.06.2026' }, avatarAsset: 'src/assets/avatars/avatar_8.jpeg' },
  { id: 100, name: 'Уэйд Джереми',    phone: '+7 999 000-00-00', email: 'guest@crazytroutarena.ru', tariff: 'standard', level: 'basic', color: '#8C5C34', visits: 1,  totalSpent: 750,   ltvK: 1,    points: 40,   pointsNext: 500,  fish: 2,   totalWeight: 3,   firstVisit: '10.07.2026', lastVisit: '10.07.2026', currentSector: 3,  bestCatch: { species: 'Карп', weight: '0.9 кг', sector: 3, date: '10.07.2026' }, avatarAsset: 'src/assets/avatars/avatar_100.jpeg' },
];

// ─── Демо-чеки ───
let _receiptSeq = 1247;
const DEMO_RECEIPTS = [
  { id: '001', number: _receiptSeq++, clientId: 1,   date: '2026-07-18 14:22', tariff: 'standard', tariffLabel: 'Стандарт', tariffPrice: 750, catches: [{ breed: 'sturgeon', label: 'Осётр', kg: 2, grams: 400, pricePerKg: 1890, sum: 4536 }], total: 5286, paymentMethod: 'card', paymentLabel: 'Картой', fiscal: true, fiscalDoc: '#48291' },
  { id: '002', number: _receiptSeq++, clientId: 2,   date: '2026-07-18 11:05', tariff: 'standard', tariffLabel: 'Стандарт', tariffPrice: 750, catches: [{ breed: 'carp', label: 'Карп', kg: 1, grams: 800, pricePerKg: 590, sum: 1062 }], total: 1812, paymentMethod: 'cash', paymentLabel: 'Наличными', fiscal: false },
  { id: '003', number: _receiptSeq++, clientId: null, date: '2026-07-18 09:40', tariff: 'guest', tariffLabel: 'Гостевой', tariffPrice: 500, catches: [], total: 500, paymentMethod: 'card', paymentLabel: 'Картой', fiscal: true, isGuest: true, fiscalDoc: '#48293' },
  { id: '004', number: _receiptSeq++, clientId: 3,   date: '2026-07-17 17:10', tariff: 'standard', tariffLabel: 'Стандарт', tariffPrice: 750, catches: [{ breed: 'trout', label: 'Форель', kg: 1, grams: 200, pricePerKg: 1200, sum: 1440 }], total: 2190, paymentMethod: 'card', paymentLabel: 'Картой', fiscal: true, fiscalDoc: '#48287' },
  { id: '005', number: _receiptSeq++, clientId: 5,   date: '2026-07-15 12:30', tariff: 'standard', tariffLabel: 'Стандарт', tariffPrice: 750, catches: [{ breed: 'sturgeon', label: 'Осётр', kg: 4, grams: 900, pricePerKg: 1890, sum: 9261 }], total: 10011, paymentMethod: 'card', paymentLabel: 'Картой', fiscal: true, fiscalDoc: '#48260' },
  { id: '006', number: _receiptSeq++, clientId: 6,   date: '2026-07-06 15:00', tariff: 'pensioner', tariffLabel: 'Пенсионер', tariffPrice: 0, catches: [{ breed: 'carp', label: 'Карп', kg: 0, grams: 900, pricePerKg: 590, sum: 531 }], total: 531, paymentMethod: 'cash', paymentLabel: 'Наличными', fiscal: false },
  { id: '007', number: _receiptSeq++, clientId: 7,   date: '2026-06-28 18:45', tariff: 'standard', tariffLabel: 'Стандарт', tariffPrice: 750, catches: [{ breed: 'amur', label: 'Амур', kg: 2, grams: 100, pricePerKg: 750, sum: 1575 }], total: 2325, paymentMethod: 'card', paymentLabel: 'Картой', fiscal: true, fiscalDoc: '#48120' },
  { id: '008', number: _receiptSeq++, clientId: 8,   date: '2026-05-30 10:15', tariff: 'standard', tariffLabel: 'Стандарт', tariffPrice: 750, catches: [{ breed: 'tench', label: 'Линь', kg: 1, grams: 400, pricePerKg: 690, sum: 966 }], total: 1716, paymentMethod: 'card', paymentLabel: 'Картой', fiscal: true, fiscalDoc: '#47950' },
  { id: '009', number: _receiptSeq++, clientId: 100, date: '2026-05-08 13:00', tariff: 'standard', tariffLabel: 'Стандарт', tariffPrice: 750, catches: [{ breed: 'sturgeon', label: 'Осётр', kg: 3, grams: 200, pricePerKg: 1890, sum: 6048 }], total: 6798, paymentMethod: 'cash', paymentLabel: 'Наличными', fiscal: false },
  { id: '010', number: _receiptSeq++, clientId: 3,   date: '2026-07-16 16:30', tariff: 'standard', tariffLabel: 'Стандарт', tariffPrice: 750, catches: [{ breed: 'carp', label: 'Карп', kg: 2, grams: 500, pricePerKg: 590, sum: 1475 }], total: 2225, paymentMethod: 'account', paymentLabel: 'Счет заведения', fiscal: true, fiscalDoc: '#48300' },
  { id: '011', number: _receiptSeq++, clientId: 6,   date: '2026-07-13 10:00', tariff: 'standard', tariffLabel: 'Стандарт', tariffPrice: 750, catches: [{ breed: 'trout', label: 'Форель', kg: 1, grams: 800, pricePerKg: 1200, sum: 2160 }], total: 2910, paymentMethod: 'account', paymentLabel: 'Счет заведения', fiscal: true, fiscalDoc: '#48295' },
  { id: '012', number: _receiptSeq++, clientId: 8,   date: '2026-07-03 14:20', tariff: 'standard', tariffLabel: 'Стандарт', tariffPrice: 750, catches: [{ breed: 'amur', label: 'Амур', kg: 1, grams: 500, pricePerKg: 750, sum: 1125 }], total: 1875, paymentMethod: 'account', paymentLabel: 'Счет заведения', fiscal: false },
  { id: '013', number: _receiptSeq++, clientId: 6,   date: '2026-07-14 11:15', tariff: 'pensioner', tariffLabel: 'Пенсионер', tariffPrice: 0, catches: [{ breed: 'tench', label: 'Линь', kg: 1, grams: 100, pricePerKg: 690, sum: 759 }], total: 759, paymentMethod: 'card', paymentLabel: 'Картой', fiscal: true, fiscalDoc: '#48270' },
  { id: '014', number: _receiptSeq++, clientId: null, date: '2026-07-12 16:00', tariff: 'guest', tariffLabel: 'Гостевой', tariffPrice: 500, catches: [{ breed: 'carp', label: 'Карп', kg: 0, grams: 800, pricePerKg: 590, sum: 472 }], total: 972, paymentMethod: 'cash', paymentLabel: 'Наличными', fiscal: true, isGuest: true, fiscalDoc: '#48265' },
  { id: '015', number: _receiptSeq++, clientId: 4,   date: '2026-07-14 11:15', tariff: 'pensioner', tariffLabel: 'Пенсионер', tariffPrice: 0, catches: [{ breed: 'tench', label: 'Линь', kg: 1, grams: 100, pricePerKg: 690, sum: 759 }], total: 759, paymentMethod: 'card', paymentLabel: 'Картой', fiscal: true, fiscalDoc: '#48270' },
  { id: '016', number: _receiptSeq++, clientId: 4,   date: '2026-06-23 14:30', tariff: 'pensioner', tariffLabel: 'Пенсионер', tariffPrice: 0, catches: [{ breed: 'carp', label: 'Карп', kg: 1, grams: 300, pricePerKg: 590, sum: 767 }], total: 767, paymentMethod: 'account', paymentLabel: 'Счет заведения', fiscal: true, fiscalDoc: '#48100' },
  { id: '017', number: _receiptSeq++, clientId: 4,   date: '2026-07-01 09:00', tariff: 'pensioner', tariffLabel: 'Пенсионер', tariffPrice: 0, catches: [{ breed: 'trout', label: 'Форель', kg: 0, grams: 700, pricePerKg: 1200, sum: 840 }], total: 840, paymentMethod: 'cash', paymentLabel: 'Наличными', fiscal: false },
  { id: '018', number: _receiptSeq++, clientId: 1,   date: '2026-07-15 10:45', tariff: 'standard', tariffLabel: 'Стандарт', tariffPrice: 750, catches: [{ breed: 'amur', label: 'Амур', kg: 1, grams: 600, pricePerKg: 750, sum: 1200 }], total: 1950, paymentMethod: 'card', paymentLabel: 'Картой', fiscal: false },
  { id: '019', number: _receiptSeq++, clientId: null, date: '2026-06-26 15:20', tariff: 'guest', tariffLabel: 'Гостевой', tariffPrice: 500, catches: [{ breed: 'tench', label: 'Линь', kg: 0, grams: 500, pricePerKg: 690, sum: 345 }], total: 845, paymentMethod: 'account', paymentLabel: 'Счет заведения', fiscal: true, isGuest: true, fiscalDoc: '#48110' },
  { id: '020', number: _receiptSeq++, clientId: null, date: '2026-06-13 13:00', tariff: 'guest', tariffLabel: 'Гостевой', tariffPrice: 500, catches: [], total: 500, paymentMethod: 'card', paymentLabel: 'Картой', fiscal: false, isGuest: true },
  { id: '021', number: _receiptSeq++, clientId: 100, date: '2026-07-18 10:30', tariff: 'standard', tariffLabel: 'Стандарт', tariffPrice: 750, catches: [{ breed: 'sturgeon', label: 'Осётр', kg: 1, grams: 500, pricePerKg: 1890, sum: 2835 }], total: 3585, paymentMethod: 'card', paymentLabel: 'Картой', fiscal: true, fiscalDoc: '#48310' },
  { id: '022', number: _receiptSeq++, clientId: 100, date: '2026-07-13 14:00', tariff: 'standard', tariffLabel: 'Стандарт', tariffPrice: 750, catches: [{ breed: 'carp', label: 'Карп', kg: 2, grams: 0, pricePerKg: 590, sum: 1180 }], total: 1930, paymentMethod: 'account', paymentLabel: 'Счет заведения', fiscal: true, fiscalDoc: '#48290' },
  { id: '023', number: _receiptSeq++, clientId: 4,   date: '2026-07-18 13:00', tariff: 'pensioner', tariffLabel: 'Пенсионер', tariffPrice: 0, catches: [{ breed: 'trout', label: 'Форель', kg: 0, grams: 900, pricePerKg: 1200, sum: 1080 }], total: 1080, paymentMethod: 'cash', paymentLabel: 'Наличными', fiscal: true, fiscalDoc: '#48315' },
  { id: '024', number: _receiptSeq++, clientId: null, date: '2026-06-08 11:00', tariff: 'guest', tariffLabel: 'Гостевой', tariffPrice: 500, catches: [{ breed: 'amur', label: 'Амур', kg: 1, grams: 0, pricePerKg: 750, sum: 750 }], total: 1250, paymentMethod: 'account', paymentLabel: 'Счет заведения', fiscal: false, isGuest: true },
  { id: '025', number: _receiptSeq++, clientId: 2,   date: '2026-07-10 15:30', tariff: 'standard', tariffLabel: 'Стандарт', tariffPrice: 750, catches: [{ breed: 'trout', label: 'Форель', kg: 1, grams: 400, pricePerKg: 1200, sum: 1680 }], total: 2430, paymentMethod: 'cash', paymentLabel: 'Наличными', fiscal: true, fiscalDoc: '#48250' },
  { id: '026', number: _receiptSeq++, clientId: 3,   date: '2026-07-18 16:00', tariff: 'standard', tariffLabel: 'Стандарт', tariffPrice: 750, catches: [{ breed: 'carp', label: 'Карп', kg: 2, grams: 200, pricePerKg: 590, sum: 1298 }], total: 2048, paymentMethod: 'account', paymentLabel: 'Счет заведения', fiscal: true, fiscalDoc: '#48320' },
  { id: '027', number: _receiptSeq++, clientId: null, date: '2026-07-18 12:00', tariff: 'guest', tariffLabel: 'Гостевой', tariffPrice: 500, catches: [{ breed: 'tench', label: 'Линь', kg: 0, grams: 600, pricePerKg: 690, sum: 414 }], total: 914, paymentMethod: 'cash', paymentLabel: 'Наличными', fiscal: true, isGuest: true, fiscalDoc: '#48318' },
  { id: '028', number: _receiptSeq++, clientId: 4,   date: '2026-07-18 15:30', tariff: 'pensioner', tariffLabel: 'Пенсионер', tariffPrice: 0, catches: [{ breed: 'carp', label: 'Карп', kg: 1, grams: 0, pricePerKg: 590, sum: 590 }], total: 590, paymentMethod: 'card', paymentLabel: 'Картой', fiscal: true, fiscalDoc: '#48322' },
];

// ─── Секторы (16 штук, как Flutter PondMapScreen) ───
// Секторы (как Flutter kPondStatsById: клиент 1→7, 3→2, 5→5, 8→8, 100→3)
const SECTORS = Array.from({ length: 16 }, (_, i) => {
  const sectorMap = { 1: 6, 2: 3, 3: 100, 4: 2, 5: 5, 7: 1, 8: 8, 10: 7 };
  const clientId = sectorMap[i + 1] || null;
  return { id: i + 1, occupied: !!clientId, clientId };
});

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
    const uniqueClients = new Set(receipts.filter(r => r.clientId).map(r => r.clientId)).size;
    const clientIds = [...new Set(receipts.filter(r => r.clientId).map(r => r.clientId))];
    const avgVisits = clientIds.length ? Math.round(clientIds.reduce((s, id) => s + (this.getClientById(id)?.visits || 0), 0) / clientIds.length) : 0;
    const avgLTV = clientIds.length ? Math.round(clientIds.reduce((s, id) => s + (this.getClientById(id)?.ltvK || 0), 0) / clientIds.length) : 0;
    const totalFish = receipts.reduce((s, r) => s + r.catches.length, 0);
    const avgFish = receipts.length ? (totalFish / receipts.length).toFixed(1) : 0;
    return { totalRevenue, avgCheck, uniqueClients, totalReceipts: receipts.length, avgVisits, avgLTV, avgFish, rating: 4.7 };
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
