// === Screen: Карта пруда (точь-в-точь Flutter pond_map_screen.dart) ===
import { store } from '../core/store.js';
import { tg } from '../core/telegram.js';
import { showClientCard } from '../widgets/client-card.js';

const FILTER_OPTIONS = [
  { value: 'all',       label: 'Все клиенты' },
  { value: 'premium',   label: 'Премиум' },
  { value: 'standard',  label: 'Стандарт' },
  { value: 'basic',     label: 'Базовый' },
];

// Демо-бронирования (как Flutter pond_map_screen.dart)
const BOOKINGS = [
  { sectorId: 2,  clientId: 1,   time: '09:00 – 13:00', date: 'Сегодня' },
  { sectorId: 5,  clientId: 100, time: '08:00 – 16:00', date: 'Сегодня' },
  { sectorId: 7,  clientId: 8,   time: '10:00 – 14:00', date: 'Сегодня' },
  { sectorId: 10, clientId: 3,   time: '12:00 – 18:00', date: 'Сегодня' },
  { sectorId: 14, clientId: 5,   time: '07:00 – 12:00', date: 'Сегодня' },
];

let currentFilter = 'all';

export function renderPondMap() {
  const occupied = store.sectors.filter(s => s.occupied).length;
  const el = document.createElement('div');
  el.className = 'screen screen-pond';
  el.innerHTML = `
    <div class="screen-title">Карта пруда</div>
    <p style="color:var(--kMuted);margin-bottom:14px;font-size:13px;">16 секторов · ${occupied} занято</p>

    <!-- Пруд с фильтрами, деревьями и картой -->
    <div class="pond-scene" style="
      position:relative;
      background:url('src/assets/pond/GrassTileB64.png') repeat, linear-gradient(180deg, #689F38 0%, #4A90A4 5%, #5BA3B5 50%, #4A90A4 95%, #689F38 100%);
      background-size:64px 64px, 100% 100%;
      border-radius:16px;
      padding:16px;
      margin-bottom:16px;
      overflow:hidden;
    ">
      <!-- Деревья сверху -->
      <div style="position:absolute;top:-8px;left:0;right:0;height:40px;display:flex;pointer-events:none;z-index:1;overflow:hidden;">
        <img src="src/assets/pond/TreeMainB64.png" style="height:40px;width:auto;flex-shrink:0;" alt="">
        <img src="src/assets/pond/TreeExtra0B64.png" style="height:36px;width:auto;flex-shrink:0;margin-left:-8px;" alt="">
        <img src="src/assets/pond/TreeExtra1B64.png" style="height:42px;width:auto;flex-shrink:0;margin-left:-6px;" alt="">
        <img src="src/assets/pond/TreeExtra2B64.png" style="height:38px;width:auto;flex-shrink:0;margin-left:-10px;" alt="">
        <img src="src/assets/pond/TreeMainB64.png" style="height:40px;width:auto;flex-shrink:0;margin-left:-8px;transform:scaleX(-1);" alt="">
        <img src="src/assets/pond/TreeExtra0B64.png" style="height:36px;width:auto;flex-shrink:0;margin-left:-8px;transform:scaleX(-1);" alt="">
        <img src="src/assets/pond/TreeExtra1B64.png" style="height:42px;width:auto;flex-shrink:0;margin-left:-6px;" alt="">
        <img src="src/assets/pond/TreeExtra2B64.png" style="height:38px;width:auto;flex-shrink:0;margin-left:-10px;transform:scaleX(-1);" alt="">
      </div>
      <!-- Деревья снизу -->
      <div style="position:absolute;bottom:-8px;left:0;right:0;height:40px;display:flex;pointer-events:none;z-index:1;overflow:hidden;">
        <img src="src/assets/pond/TreeExtra1B64.png" style="height:40px;width:auto;flex-shrink:0;transform:scaleY(-1);" alt="">
        <img src="src/assets/pond/TreeMainB64.png" style="height:38px;width:auto;flex-shrink:0;margin-left:-8px;transform:scaleY(-1);" alt="">
        <img src="src/assets/pond/TreeExtra2B64.png" style="height:42px;width:auto;flex-shrink:0;margin-left:-6px;transform:scale(-1,-1);" alt="">
        <img src="src/assets/pond/TreeExtra0B64.png" style="height:36px;width:auto;flex-shrink:0;margin-left:-10px;transform:scaleY(-1);" alt="">
      </div>
      <!-- Деревья слева -->
      <div style="position:absolute;top:0;left:-8px;bottom:0;width:40px;display:flex;flex-direction:column;pointer-events:none;z-index:1;overflow:hidden;">
        <img src="src/assets/pond/TreeMainB64.png" style="width:40px;height:auto;flex-shrink:0;transform:rotate(90deg);" alt="">
        <img src="src/assets/pond/TreeExtra1B64.png" style="width:36px;height:auto;flex-shrink:0;margin-top:-8px;transform:rotate(90deg);" alt="">
      </div>
      <!-- Деревья справа -->
      <div style="position:absolute;top:0;right:-8px;bottom:0;width:40px;display:flex;flex-direction:column;pointer-events:none;z-index:1;overflow:hidden;">
        <img src="src/assets/pond/TreeExtra2B64.png" style="width:40px;height:auto;flex-shrink:0;transform:rotate(-90deg);" alt="">
        <img src="src/assets/pond/TreeMainB64.png" style="width:36px;height:auto;flex-shrink:0;margin-top:-8px;transform:rotate(-90deg);" alt="">
      </div>
      <!-- Кувшинки -->
      <img src="src/assets/pond/GrassTileB64.png" style="position:absolute;top:30%;left:15%;width:18px;height:18px;border-radius:50%;opacity:0.5;pointer-events:none;" alt="">
      <img src="src/assets/pond/GrassTileB64.png" style="position:absolute;top:60%;right:20%;width:14px;height:14px;border-radius:50%;opacity:0.4;pointer-events:none;" alt="">
      <!-- Рябь -->
      <div style="position:absolute;top:25%;left:40%;width:40px;height:2px;background:rgba(255,255,255,0.15);border-radius:50%;pointer-events:none;"></div>
      <div style="position:absolute;top:55%;left:25%;width:30px;height:2px;background:rgba(255,255,255,0.12);border-radius:50%;pointer-events:none;"></div>

      <!-- Фильтры ВНУТРИ сцены -->
      <div id="pond-filters" style="display:flex;gap:6px;margin-bottom:12px;position:relative;z-index:3;flex-wrap:wrap;">
        ${FILTER_OPTIONS.map(f => `
          <div class="chip ${f.value === currentFilter ? 'selected' : ''}" data-filter="${f.value}" style="font-size:12px;padding:6px 10px;">${f.label}</div>
        `).join('')}
      </div>

      <!-- Карта секторов -->
      <div class="pond-grid" id="pond-grid" style="position:relative;z-index:2;"></div>
    </div>

    <!-- Легенда -->
    <div style="display:flex;gap:16px;margin-bottom:14px;font-size:12px;">
      <div style="display:flex;align-items:center;gap:4px;">
        <div style="width:12px;height:12px;border-radius:3px;background:var(--kFill);"></div>
        <span style="color:var(--kMuted2);">Свободен</span>
      </div>
      <div style="display:flex;align-items:center;gap:4px;">
        <div style="width:12px;height:12px;border-radius:3px;background:rgba(232,145,43,0.1);border:1px solid var(--kOrange);"></div>
        <span style="color:var(--kMuted2);">Занят</span>
      </div>
    </div>

    <!-- Расписание / Лента броней -->
    <div class="card" style="margin-bottom:14px;">
      <div class="card-header"><div class="card-title">Расписание на сегодня</div></div>
      <div id="booking-feed"></div>
    </div>

    <!-- Детали сектора -->
    <div id="sector-details" class="card sector-detail hidden"></div>
  `;

  setTimeout(() => {
    renderSectorGrid();
    renderBookingFeed();
    initPondHandlers();
  }, 0);
  return el;
}

function renderSectorGrid() {
  const grid = document.getElementById('pond-grid');
  if (!grid) return;

  grid.innerHTML = store.sectors.map(sector => {
    const client = sector.occupied ? store.getClientById(sector.clientId) : null;
    const matchesFilter = currentFilter === 'all' || (client && client.level === currentFilter) || !sector.occupied;
    if (!matchesFilter && sector.occupied) return '';
    return `
      <div class="sector-cell ${sector.occupied ? 'occupied' : ''}" data-sector="${sector.id}" data-client-id="${sector.clientId || ''}">
        <div class="sector-number">${sector.id}</div>
        <div class="sector-status">${sector.occupied ? (client ? store.getClientInitials(client) : '👤') : 'Свободен'}</div>
      </div>
    `;
  }).join('');
}

function renderBookingFeed() {
  const feed = document.getElementById('booking-feed');
  if (!feed) return;

  if (!BOOKINGS.length) {
    feed.innerHTML = '<p style="color:var(--kMuted2);font-size:13px;text-align:center;padding:12px;">Нет бронирований</p>';
    return;
  }

  feed.innerHTML = BOOKINGS.map(b => {
    const client = store.getClientById(b.clientId);
    return `
      <div style="display:flex;align-items:center;gap:10px;padding:10px 0;border-bottom:0.5px solid var(--kHairline2);">
        <div style="width:36px;height:36px;border-radius:8px;background:var(--kFill);display:flex;align-items:center;justify-content:center;font-size:14px;font-weight:700;color:var(--kOrange);flex-shrink:0;">
          ${b.sectorId}
        </div>
        <div style="flex:1;min-width:0;">
          <div style="font-size:13px;font-weight:600;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">${client?.name || 'Гость'}</div>
          <div style="font-size:11px;color:var(--kMuted2);">${b.date} · ${b.time}</div>
        </div>
        ${store.renderAvatar(client, 32)}
      </div>
    `;
  }).join('');
}

function initPondHandlers() {
  // Фильтры
  document.getElementById('pond-filters')?.addEventListener('click', (e) => {
    const chip = e.target.closest('.chip');
    if (!chip) return;
    currentFilter = chip.dataset.filter;
    document.querySelectorAll('#pond-filters .chip').forEach(c => c.classList.remove('selected'));
    chip.classList.add('selected');
    renderSectorGrid();
    tg.hapticSelection();
  });

  // Клик по сектору
  document.getElementById('pond-grid')?.addEventListener('click', (e) => {
    const cell = e.target.closest('.sector-cell');
    if (!cell) return;
    document.querySelectorAll('.sector-cell').forEach(c => c.classList.remove('selected'));
    cell.classList.add('selected');
    tg.hapticImpact('light');

    const sectorId = cell.dataset.sector;
    const clientId = cell.dataset.clientId;
    const client = clientId ? store.getClientById(clientId) : null;
    const details = document.getElementById('sector-details');

    if (details) {
      details.classList.remove('hidden');
      if (client) {
        const ltv = store.getClientLTV(client.id);
        const avgCatch = store.getClientAvgCatch(client.id);
        const badge = store.getLevelBadge(client.level);
        const booking = BOOKINGS.find(b => b.sectorId === parseInt(sectorId));
        details.innerHTML = `
          <div class="card-header">
            <div class="card-title">Сектор ${sectorId}</div>
            <span class="badge ${badge.cssClass}">${badge.letter}</span>
          </div>
          <div style="display:flex;align-items:center;gap:12px;margin-bottom:12px;cursor:pointer;" id="sector-client-link">
            ${store.renderAvatar(client, 40)}
            <div>
              <div style="font-weight:700;">${client.name}</div>
              <div style="font-size:12px;color:var(--kMuted2);">${client.phone}</div>
            </div>
          </div>
          ${booking ? `<div style="font-size:12px;color:var(--kMuted);margin-bottom:12px;">📅 ${booking.date} · ${booking.time}</div>` : ''}
          <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:8px;text-align:center;">
            <div>
              <div style="font-size:18px;font-weight:700;color:var(--kOrange);">${client.visits}</div>
              <div style="font-size:10px;color:var(--kMuted2);margin-top:2px;">Посещений</div>
            </div>
            <div>
              <div style="font-size:18px;font-weight:700;color:var(--kOrange);">${store.formatMoney(ltv)} ₽</div>
              <div style="font-size:10px;color:var(--kMuted2);margin-top:2px;">LTV</div>
            </div>
            <div>
              <div style="font-size:18px;font-weight:700;color:var(--kOrange);">${avgCatch.kg} кг</div>
              <div style="font-size:10px;color:var(--kMuted2);margin-top:2px;">Ср. улов</div>
            </div>
          </div>
        `;
        // Клик по имени → карточка клиента
        document.getElementById('sector-client-link')?.addEventListener('click', () => {
          showClientCard(client.id);
        });
      } else {
        details.innerHTML = `
          <div class="card-header">
            <div class="card-title">Сектор ${sectorId}</div>
            <span style="font-size:11px;padding:4px 8px;background:rgba(76,175,80,0.12);color:#4CAF50;border-radius:50%;font-weight:700;">Свободен</span>
          </div>
          <p style="color:var(--kMuted2);font-size:13px;">Сектор пуст. Назначить клиента можно через экран Чек.</p>
        `;
      }
    }
  });
}
