// === Screen: Карта пруда (точь-в-точь Flutter pond_map_screen.dart) ===
import { store } from '../core/store.js';
import { tg } from '../core/telegram.js';

const FILTER_OPTIONS = [
  { value: 'all',       label: 'Все клиенты' },
  { value: 'premium',   label: 'Премиум' },
  { value: 'standard',  label: 'Стандарт' },
  { value: 'basic',     label: 'Базовый' },
];

let currentFilter = 'all';

export function renderPondMap() {
  const occupied = store.sectors.filter(s => s.occupied).length;
  const el = document.createElement('div');
  el.className = 'screen screen-pond';
  el.innerHTML = `
    <div class="screen-title">Карта пруда</div>
    <p style="color:var(--kMuted);margin-bottom:14px;font-size:13px;">16 секторов · ${occupied} занято</p>

    <!-- Фильтры -->
    <div class="filter-bar" id="pond-filters">
      ${FILTER_OPTIONS.map(f => `
        <div class="chip ${f.value === currentFilter ? 'selected' : ''}" data-filter="${f.value}">${f.label}</div>
      `).join('')}
    </div>

    <!-- Пруд с реальными деревьями и текстурой (из Flutter base64) -->
    <div class="pond-scene" style="
      position:relative;
      background:url('src/assets/pond/GrassTileB64.png') repeat, linear-gradient(180deg, #689F38 0%, #4A90A4 5%, #5BA3B5 50%, #4A90A4 95%, #689F38 100%);
      background-size: 64px 64px, 100% 100%;
      border-radius:16px;
      padding:20px;
      margin-bottom:16px;
      overflow:hidden;
    ">
      <!-- Деревья сверху (4 текстуры по кругу) -->
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
        <img src="src/assets/pond/TreeExtra1B64.png" style="height:40px;width:auto;flex-shrink:0;margin-left:-8px;transform:scale(-1,-1);" alt="">
        <img src="src/assets/pond/TreeMainB64.png" style="height:38px;width:auto;flex-shrink:0;margin-left:-8px;transform:scaleY(-1);" alt="">
        <img src="src/assets/pond/TreeExtra2B64.png" style="height:42px;width:auto;flex-shrink:0;margin-left:-6px;transform:scale(-1,-1);" alt="">
        <img src="src/assets/pond/TreeExtra0B64.png" style="height:36px;width:auto;flex-shrink:0;margin-left:-10px;transform:scale(-1,-1);" alt="">
      </div>
      <!-- Деревья слева -->
      <div style="position:absolute;top:0;left:-8px;bottom:0;width:40px;display:flex;flex-direction:column;pointer-events:none;z-index:1;overflow:hidden;">
        <img src="src/assets/pond/TreeMainB64.png" style="width:40px;height:auto;flex-shrink:0;transform:rotate(90deg);" alt="">
        <img src="src/assets/pond/TreeExtra1B64.png" style="width:36px;height:auto;flex-shrink:0;margin-top:-8px;transform:rotate(90deg);" alt="">
        <img src="src/assets/pond/TreeExtra0B64.png" style="width:42px;height:auto;flex-shrink:0;margin-top:-6px;transform:rotate(90deg);" alt="">
        <img src="src/assets/pond/TreeExtra2B64.png" style="width:38px;height:auto;flex-shrink:0;margin-top:-10px;transform:rotate(90deg);" alt="">
      </div>
      <!-- Деревья справа -->
      <div style="position:absolute;top:0;right:-8px;bottom:0;width:40px;display:flex;flex-direction:column;pointer-events:none;z-index:1;overflow:hidden;">
        <img src="src/assets/pond/TreeExtra2B64.png" style="width:40px;height:auto;flex-shrink:0;transform:rotate(-90deg);" alt="">
        <img src="src/assets/pond/TreeMainB64.png" style="width:36px;height:auto;flex-shrink:0;margin-top:-8px;transform:rotate(-90deg);" alt="">
        <img src="src/assets/pond/TreeExtra1B64.png" style="width:42px;height:auto;flex-shrink:0;margin-top:-6px;transform:rotate(-90deg);" alt="">
        <img src="src/assets/pond/TreeExtra0B64.png" style="width:38px;height:auto;flex-shrink:0;margin-top:-10px;transform:rotate(-90deg);" alt="">
      </div>
      <!-- Кувшинки -->
      <img src="src/assets/pond/GrassTileB64.png" style="position:absolute;top:30%;left:15%;width:18px;height:18px;border-radius:50%;opacity:0.5;pointer-events:none;" alt="">
      <img src="src/assets/pond/GrassTileB64.png" style="position:absolute;top:60%;right:20%;width:14px;height:14px;border-radius:50%;opacity:0.4;pointer-events:none;" alt="">
      <img src="src/assets/pond/GrassTileB64.png" style="position:absolute;top:45%;left:70%;width:16px;height:16px;border-radius:50%;opacity:0.45;pointer-events:none;" alt="">
      <!-- Рябь воды -->
      <div style="position:absolute;top:25%;left:40%;width:40px;height:2px;background:rgba(255,255,255,0.15);border-radius:50%;pointer-events:none;"></div>
      <div style="position:absolute;top:55%;left:25%;width:30px;height:2px;background:rgba(255,255,255,0.12);border-radius:50%;pointer-events:none;"></div>
      <div style="position:absolute;top:70%;right:35%;width:35px;height:2px;background:rgba(255,255,255,0.10);border-radius:50%;pointer-events:none;"></div>

      <!-- Карта секторов -->
      <div class="pond-grid" id="pond-grid" style="position:relative;z-index:2;"></div>
    </div>

    <!-- Легенда -->
    <div class="legend">
      <div class="legend-item">
        <div class="legend-swatch" style="background:var(--kFill);"></div>
        <span style="color:var(--kMuted2);">Свободен</span>
      </div>
      <div class="legend-item">
        <div class="legend-swatch" style="background:rgba(232,145,43,0.1);border:1px solid var(--kOrange);"></div>
        <span style="color:var(--kMuted2);">Занят</span>
      </div>
    </div>

    <!-- Детали сектора -->
    <div id="sector-details" class="card sector-detail hidden"></div>
  `;

  setTimeout(() => {
    renderSectorGrid();
    initPondHandlers();
  }, 0);
  return el;
}

function renderSectorGrid() {
  const grid = document.getElementById('pond-grid');
  if (!grid) return;
  const filtered = store.sectors.filter(s => {
    if (currentFilter === 'all') return true;
    if (!s.occupied) return false;
    const client = store.getClientById(s.clientId);
    return client && client.level === currentFilter;
  });

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
        details.innerHTML = `
          <div class="card-header">
            <div class="card-title">Сектор ${sectorId}</div>
            <span class="badge ${badge.cssClass}">${badge.letter}</span>
          </div>
          <div style="display:flex;align-items:center;gap:12px;margin-bottom:12px;">
            ${store.renderAvatar(client, 40)}
            <div>
              <div style="font-weight:700;">${client.name}</div>
              <div style="font-size:12px;color:var(--kMuted2);">${client.phone}</div>
            </div>
          </div>
          <div class="stat-grid">
            <div>
              <div class="stat-value">${client.visits}</div>
              <div class="stat-label">Посещений</div>
            </div>
            <div>
              <div class="stat-value">${store.formatMoney(ltv)} ₽</div>
              <div class="stat-label">LTV</div>
            </div>
            <div>
              <div class="stat-value">${avgCatch.kg} кг</div>
              <div class="stat-label">Ср. улов</div>
            </div>
          </div>
        `;
      } else {
        details.innerHTML = `
          <div class="card-header">
            <div class="card-title">Сектор ${sectorId}</div>
            <span class="chip selected" style="font-size:11px;padding:4px 8px;">Свободен</span>
          </div>
          <p style="color:var(--kMuted2);font-size:13px;">Сектор пуст. Назначить клиента можно через экран Чек.</p>
        `;
      }
    }
  });
}
