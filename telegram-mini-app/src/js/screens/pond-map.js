// === Screen: Карта пруда (точь-в-точь Flutter pond_map_screen.dart) ===
import { store } from '../core/store.js';
import { tg } from '../core/telegram.js';
import { showClientCard } from '../widgets/client-card.js';
import { showCalendarPicker } from '../widgets/calendar.js';

const FILTER_OPTIONS = [
  { value: 'none',      label: 'Нет' },
  { value: 'all',       label: 'Все' },
  { value: 'premium',   label: 'Премиум' },
  { value: 'standard',  label: 'Стандарт' },
  { value: 'basic',     label: 'Базовый' },
];

// Временные блоки (как Flutter pond_map_screen.dart _TimeBlock)
const TIME_BLOCKS = [
  { id: 'early',   label: 'Ранняя рыбалка', time: '05:00 – 08:00',  icon: '🌅' },
  { id: 'morning', label: 'Утро',           time: '08:00 – 11:00',  icon: '☀️' },
  { id: 'midday',  label: 'День',           time: '11:00 – 14:00',  icon: '🌤️' },
  { id: 'afternoon', label: 'После обеда',  time: '14:00 – 17:00',  icon: '⛅' },
  { id: 'evening', label: 'Вечер',          time: '17:00 – 20:00',  icon: '🌆' },
  { id: 'night',   label: 'Ночь',           time: '20:00 – 22:00',  icon: '🌙' },
];

// Демо-бронирования (как Flutter _seededRandom)
const BOOKINGS = [
  { sectorId: 7,  clientId: 1,   blockId: 'morning',  date: 'Сегодня' },
  { sectorId: 3,  clientId: 100, blockId: 'early',    date: 'Сегодня' },
  { sectorId: 8,  clientId: 8,   blockId: 'midday',   date: 'Сегодня' },
  { sectorId: 2,  clientId: 3,   blockId: 'afternoon', date: 'Сегодня' },
  { sectorId: 5,  clientId: 5,   blockId: 'early',    date: 'Сегодня' },
];

let currentFilter = 'none';

// ─── Catmull-Rom сплайн (точь-в-точь Flutter _catmullRomSpline) ───
function catmullRomSpline(points, segments = 12) {
  const result = [];
  const n = points.length;
  for (let i = 0; i < n; i++) {
    const p0 = points[(i - 1 + n) % n];
    const p1 = points[i];
    const p2 = points[(i + 1) % n];
    const p3 = points[(i + 2) % n];
    for (let t = 0; t < segments; t++) {
      const s = t / segments;
      const s2 = s * s;
      const s3 = s2 * s;
      result.push({
        x: 0.5 * ((2 * p1.x) + (-p0.x + p2.x) * s + (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * s2 + (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * s3),
        y: 0.5 * ((2 * p1.y) + (-p0.y + p2.y) * s + (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * s2 + (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * s3),
      });
    }
  }
  return result;
}

// ─── Точки сплайна пруда (из Flutter) ───
function getPondSplinePoints(w, h) {
  return [
    { x: w * 0.50, y: h * 0.02 }, { x: w * 0.78, y: h * 0.03 },
    { x: w * 0.95, y: h * 0.18 }, { x: w * 0.98, y: h * 0.35 },
    { x: w * 0.97, y: h * 0.55 }, { x: w * 0.93, y: h * 0.72 },
    { x: w * 0.80, y: h * 0.88 }, { x: w * 0.60, y: h * 0.96 },
    { x: w * 0.40, y: h * 0.97 }, { x: w * 0.22, y: h * 0.90 },
    { x: w * 0.08, y: h * 0.75 }, { x: w * 0.03, y: h * 0.55 },
    { x: w * 0.02, y: h * 0.35 }, { x: w * 0.08, y: h * 0.18 },
    { x: w * 0.25, y: h * 0.05 }, { x: w * 0.40, y: h * 0.02 },
  ];
}

export function renderPondMap() {
  const occupied = store.sectors.filter(s => s.occupied).length;
  const el = document.createElement('div');
  el.className = 'screen screen-pond';
  el.innerHTML = `
    <div class="screen-title">Карта пруда</div>
    <div style="display:flex;gap:10px;margin-bottom:14px;">
      <div style="flex:1;background:linear-gradient(135deg,#1F1D18,#14130F);border-radius:18px;border:1px solid rgba(255,255,255,0.1);padding:16px;position:relative;overflow:hidden;">
        <div style="position:absolute;top:-30px;right:-30px;width:110px;height:110px;border-radius:50%;background:radial-gradient(circle,rgba(232,145,43,0.20),transparent 70%);pointer-events:none;"></div>
        <div style="display:flex;align-items:center;gap:6px;margin-bottom:10px;">
          <div style="width:22px;height:22px;border-radius:7px;background:rgba(255,255,255,0.1);display:flex;align-items:center;justify-content:center;"><span style="font-size:13px;">📊</span></div>
          <span style="font-size:10.5px;font-weight:700;letter-spacing:0.5px;color:rgba(255,255,255,0.54);">ЗАГРУЗКА</span>
        </div>
        <div style="text-align:center;font-size:26px;font-weight:800;color:var(--kOrange);">${Math.round(occupied / 16 * 100)}%</div>
      </div>
      <div style="flex:1;background:linear-gradient(135deg,#fff,#FCFAF4);border-radius:18px;border:1px solid var(--kHairline);padding:16px;">
        <div style="display:flex;align-items:center;gap:6px;margin-bottom:10px;">
          <div style="width:22px;height:22px;border-radius:7px;background:rgba(136,111,17,0.1);display:flex;align-items:center;justify-content:center;"><span style="font-size:13px;">📅</span></div>
          <span style="font-size:10.5px;font-weight:700;letter-spacing:0.5px;color:rgba(0,0,0,0.45);">БРОНЕЙ</span>
        </div>
        <div style="text-align:center;font-size:26px;font-weight:800;color:var(--kInk);">${occupied} / 16</div>
      </div>
    </div>

    <!-- Пруд с Canvas-рендерингом (как Flutter CustomPainter) -->
    <div id="pond-canvas-wrap" style="position:relative;margin-bottom:16px;border-radius:16px;overflow:hidden;">
      <canvas id="pond-canvas" style="width:100%;display:block;"></canvas>
      <!-- Фильтры ВНУТРИ сцены -->
      <div id="pond-filters" style="position:absolute;top:12px;left:12px;right:12px;display:flex;gap:6px;z-index:3;flex-wrap:wrap;">
        ${FILTER_OPTIONS.map(f => `
          <div class="chip ${f.value === currentFilter ? 'selected' : ''}" data-filter="${f.value}" style="font-size:12px;padding:6px 10px;">${f.label}</div>
        `).join('')}
      </div>
      <!-- Маркеры секторов (поверх Canvas) -->
      <div id="pond-grid" style="position:absolute;inset:0;z-index:2;"></div>
    </div>

    <!-- Легенда (цвет как Flutter _green = #3FA66B) -->
    <div style="display:flex;gap:16px;margin-bottom:14px;font-size:13px;">
      <div style="display:flex;align-items:center;gap:6px;">
        <div style="width:8px;height:8px;border-radius:50%;background:#3FA66B;"></div>
        <span style="color:var(--kInk);">Свободно ${16 - occupied}</span>
      </div>
      <div style="display:flex;align-items:center;gap:6px;">
        <div style="width:8px;height:8px;border-radius:50%;background:var(--kOrange);"></div>
        <span style="color:var(--kInk);">Занято ${occupied}</span>
      </div>
    </div>

    <!-- Расписание сгруппированное по временным блокам -->
    <div class="card" style="margin-bottom:14px;">
      <div class="card-header"><div class="card-title">Расписание</div></div>
      <div id="booking-feed"></div>
    </div>

    <!-- Детали сектора -->
    <div id="sector-details" class="card sector-detail hidden"></div>
  `;

  setTimeout(() => {
    renderPondCanvas();
    renderSectorMarkers();
    renderBookingFeed();
    initPondHandlers();
  }, 0);
  return el;
}

// ─── Canvas рендеринг пруда (точь-в-точь Flutter _PondPainter) ───
function renderPondCanvas() {
  const canvas = document.getElementById('pond-canvas');
  if (!canvas) return;
  const wrap = canvas.parentElement;
  const W = wrap.offsetWidth;
  const H = Math.round(W * 0.7);
  canvas.width = W * 2;
  canvas.height = H * 2;
  canvas.style.height = H + 'px';
  const ctx = canvas.getContext('2d');
  ctx.scale(2, 2);

  // 1. Фон — трава (зелёный)
  const grassGrad = ctx.createRadialGradient(W / 2, H / 2, 0, W / 2, H / 2, W * 0.7);
  grassGrad.addColorStop(0, '#5A9B3A');
  grassGrad.addColorStop(1, '#3D7A24');
  ctx.fillStyle = grassGrad;
  ctx.fillRect(0, 0, W, H);

  // 2. Сплайн пруда
  const splinePts = catmullRomSpline(getPondSplinePoints(W, H));

  // Берег/дорожка
  ctx.beginPath();
  splinePts.forEach((p, i) => i === 0 ? ctx.moveTo(p.x, p.y) : ctx.lineTo(p.x, p.y));
  ctx.closePath();
  const bankGrad = ctx.createLinearGradient(0, 0, W, H);
  bankGrad.addColorStop(0, '#E4C486');
  bankGrad.addColorStop(1, '#B4874A');
  ctx.strokeStyle = bankGrad;
  ctx.lineWidth = 16;
  ctx.stroke();

  // Вода
  ctx.save();
  ctx.beginPath();
  splinePts.forEach((p, i) => i === 0 ? ctx.moveTo(p.x, p.y) : ctx.lineTo(p.x, p.y));
  ctx.closePath();
  ctx.clip();
  const waterGrad = ctx.createRadialGradient(W * 0.45, H * 0.4, W * 0.05, W * 0.5, H * 0.5, W * 0.55);
  waterGrad.addColorStop(0, '#4AA0C6');
  waterGrad.addColorStop(0.4, '#2B7A9B');
  waterGrad.addColorStop(0.75, '#1A5C78');
  waterGrad.addColorStop(1, '#0F4C6C');
  ctx.fillStyle = waterGrad;
  ctx.fillRect(0, 0, W, H);

  // Блики
  ctx.globalAlpha = 0.05;
  ctx.fillStyle = '#fff';
  ctx.beginPath(); ctx.ellipse(W * 0.38, H * 0.28, W * 0.14, H * 0.10, 0, 0, Math.PI * 2); ctx.fill();
  ctx.globalAlpha = 0.06;
  ctx.beginPath(); ctx.ellipse(W * 0.55, H * 0.23, W * 0.10, H * 0.06, 0, 0, Math.PI * 2); ctx.fill();

  // Рябь
  ctx.globalAlpha = 0.12;
  ctx.strokeStyle = '#fff';
  ctx.lineWidth = 1;
  [[0.28, 0.50, 24, 4], [0.65, 0.35, 18, 3], [0.48, 0.70, 20, 3]].forEach(([rx, ry, rw, rh]) => {
    ctx.beginPath(); ctx.ellipse(W * rx, H * ry, rw, rh, 0, 0, Math.PI * 2); ctx.stroke();
  });
  ctx.globalAlpha = 1;

  // Кувшинки
  [[0.15, 0.25], [0.75, 0.38], [0.32, 0.72], [0.82, 0.65], [0.55, 0.85]].forEach(([lx, ly]) => {
    ctx.globalAlpha = 0.6;
    ctx.fillStyle = '#3D8B37';
    ctx.beginPath(); ctx.ellipse(W * lx, H * ly, 9, 6, 0, 0, Math.PI * 2); ctx.fill();
    ctx.globalAlpha = 0.9;
    ctx.fillStyle = '#2D6B27';
    ctx.beginPath(); ctx.arc(W * lx, H * ly, 3, 0, Math.PI * 2); ctx.fill();
    ctx.strokeStyle = '#1A5C14'; ctx.lineWidth = 0.5;
    ctx.beginPath(); ctx.moveTo(W * lx, H * ly); ctx.lineTo(W * lx + 8, H * ly - 4); ctx.stroke();
    ctx.globalAlpha = 1;
  });

  // Деревья по периметру
  const treePositions = [
    [0.08, 0.05], [0.22, 0.02], [0.38, 0.01], [0.55, 0.02], [0.72, 0.04], [0.88, 0.08],
    [0.96, 0.22], [0.98, 0.42], [0.97, 0.62], [0.94, 0.78],
    [0.85, 0.90], [0.68, 0.95], [0.50, 0.97], [0.32, 0.95], [0.15, 0.88],
    [0.04, 0.72], [0.02, 0.52], [0.03, 0.32], [0.05, 0.15],
  ];
  treePositions.forEach(([tx, ty]) => {
    ctx.fillStyle = '#2D5016';
    ctx.beginPath(); ctx.arc(W * tx, H * ty, 14 + Math.random() * 6, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#3D7A24';
    ctx.beginPath(); ctx.arc(W * tx - 3, H * ty - 3, 10 + Math.random() * 4, 0, Math.PI * 2); ctx.fill();
  });

  // Кусты
  [[0.08, 0.42], [0.92, 0.15], [0.88, 0.82], [0.12, 0.82]].forEach(([bx, by]) => {
    ctx.fillStyle = '#3D7A24';
    ctx.beginPath(); ctx.arc(W * bx, H * by, 8, 0, Math.PI * 2); ctx.fill();
    ctx.beginPath(); ctx.arc(W * bx + 6, H * by + 3, 6, 0, Math.PI * 2); ctx.fill();
    ctx.beginPath(); ctx.arc(W * bx - 4, H * by + 5, 7, 0, Math.PI * 2); ctx.fill();
  });

  // Тростник
  [[0.05, 0.25], [0.95, 0.45], [0.08, 0.65]].forEach(([rx, ry]) => {
    ctx.strokeStyle = '#5A7A3A'; ctx.lineWidth = 1.5;
    for (let i = 0; i < 3; i++) {
      ctx.beginPath(); ctx.moveTo(W * rx + i * 4, H * ry); ctx.lineTo(W * rx + i * 4 - 2, H * ry - 20); ctx.stroke();
    }
  });

  // Удочки у занятых секторов
  store.sectors.filter(s => s.occupied).forEach(s => {
    const pos = getSectorPosition(s.id, W, H);
    if (!pos) return;
    ctx.strokeStyle = '#8B6914'; ctx.lineWidth = 1.5;
    ctx.beginPath(); ctx.moveTo(pos.x, pos.y); ctx.lineTo(pos.x + 30, pos.y - 40); ctx.stroke();
    ctx.strokeStyle = 'rgba(255,255,255,0.4)'; ctx.lineWidth = 0.5;
    ctx.beginPath(); ctx.moveTo(pos.x + 30, pos.y - 40); ctx.lineTo(pos.x + 35, pos.y - 10); ctx.stroke();
    ctx.fillStyle = '#FF6B35'; ctx.beginPath(); ctx.arc(pos.x + 35, pos.y - 10, 2.5, 0, Math.PI * 2); ctx.fill();
    ctx.strokeStyle = 'rgba(255,255,255,0.18)'; ctx.lineWidth = 0.5;
    ctx.beginPath(); ctx.ellipse(pos.x + 35, pos.y - 6, 10, 3, 0, 0, Math.PI * 2); ctx.stroke();
  });

  ctx.restore();
}

function getSectorPosition(sectorId, W, H) {
  const positions = {
    1: [0.18, 0.18], 2: [0.38, 0.15], 3: [0.58, 0.18], 4: [0.78, 0.18],
    5: [0.18, 0.38], 6: [0.38, 0.35], 7: [0.58, 0.38], 8: [0.78, 0.38],
    9: [0.18, 0.58], 10: [0.38, 0.55], 11: [0.58, 0.58], 12: [0.78, 0.58],
    13: [0.18, 0.78], 14: [0.38, 0.75], 15: [0.58, 0.78], 16: [0.78, 0.78],
  };
  const p = positions[sectorId];
  return p ? { x: p[0] * W, y: p[1] * H } : null;
}

// ─── Маркеры секторов (поверх Canvas) ───
function renderSectorMarkers() {
  const grid = document.getElementById('pond-grid');
  if (!grid) return;
  const canvas = document.getElementById('pond-canvas');
  const W = canvas.parentElement.offsetWidth;
  const H = Math.round(W * 0.7);

  grid.style.position = 'relative';
  grid.style.width = W + 'px';
  grid.style.height = H + 'px';

  grid.innerHTML = store.sectors.map(sector => {
    const client = sector.occupied ? store.getClientById(sector.clientId) : null;
    const matchesFilter = currentFilter === 'none' || currentFilter === 'all' || (client && client.level === currentFilter) || !sector.occupied;
    if (!matchesFilter && sector.occupied) return '';
    const pos = getSectorPosition(sector.id, W, H);
    if (!pos) return '';
    const isOccupied = sector.occupied;
    const bg = isOccupied ? 'var(--kOrange)' : '#3FA66B';
    return `
      <div class="sector-marker ${isOccupied ? 'occupied' : ''}" data-sector="${sector.id}" data-client-id="${sector.clientId || ''}" style="
        position:absolute;
        left:${pos.x - 20}px;top:${pos.y - 20}px;
        width:40px;height:40px;
        border-radius:50%;
        background:${bg};
        display:flex;flex-direction:column;align-items:center;justify-content:center;
        cursor:pointer;
        box-shadow:0 1px 3px rgba(0,0,0,0.3);
        transition:transform 0.15s;
        border:2.5px solid ${isOccupied ? '#E07B1F' : '#2D8A4E'};
      ">
        <span style="font-size:15px;font-weight:800;color:#fff;line-height:1;">${sector.id}</span>
        <span style="font-size:7px;color:rgba(255,255,255,0.8);line-height:1;">${isOccupied ? (client ? store.getClientInitials(client) : '👤') : 'Своб.'}</span>
      </div>
    `;
  }).join('');
}

function renderBookingFeed() {
  const feed = document.getElementById('booking-feed');
  if (!feed) return;

  const grouped = {};
  TIME_BLOCKS.forEach(b => { grouped[b.id] = []; });
  BOOKINGS.forEach(b => {
    if (grouped[b.blockId]) grouped[b.blockId].push(b);
  });

  let html = '';
  TIME_BLOCKS.forEach(block => {
    const bookings = grouped[block.id];
    if (!bookings || !bookings.length) return;
    html += `<div style="padding:10px 0;border-bottom:0.5px solid var(--kHairline2);">
      <div style="display:flex;align-items:center;gap:8px;margin-bottom:8px;">
        <span style="font-size:16px;">${block.icon}</span>
        <div>
          <div style="font-size:13px;font-weight:700;color:var(--kInk);">${block.label}</div>
          <div style="font-size:11px;color:var(--kMuted2);">${block.time}</div>
        </div>
      </div>`;
    bookings.forEach(b => {
      const client = store.getClientById(b.clientId);
      html += `
        <div style="display:flex;align-items:center;gap:10px;padding:6px 0 6px 28px;">
          <div style="width:32px;height:32px;border-radius:8px;background:var(--kFill);display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:700;color:var(--kOrange);flex-shrink:0;">
            ${b.sectorId}
          </div>
          <div style="flex:1;min-width:0;">
            <div style="font-size:12px;font-weight:600;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">${client?.name || 'Гость'}</div>
            <div style="font-size:10px;color:var(--kMuted2);">${b.date}</div>
          </div>
          ${store.renderAvatar(client, 28)}
        </div>`;
    });
    html += '</div>';
  });

  if (!html) {
    feed.innerHTML = '<p style="color:var(--kMuted2);font-size:13px;text-align:center;padding:12px;">Нет бронирований</p>';
  } else {
    feed.innerHTML = html;
  }
}

function initPondHandlers() {
  document.getElementById('pond-filters')?.addEventListener('click', (e) => {
    const chip = e.target.closest('.chip');
    if (!chip) return;
    currentFilter = chip.dataset.filter;
    document.querySelectorAll('#pond-filters .chip').forEach(c => c.classList.remove('selected'));
    chip.classList.add('selected');
    renderSectorMarkers();
    tg.hapticSelection();
  });

  document.getElementById('pond-grid')?.addEventListener('click', (e) => {
    const marker = e.target.closest('.sector-marker');
    if (!marker) return;
    document.querySelectorAll('.sector-marker').forEach(c => c.style.transform = '');
    marker.style.transform = 'scale(1.18)';
    tg.hapticImpact('light');

    const sectorId = marker.dataset.sector;
    const clientId = marker.dataset.clientId;
    const client = clientId ? store.getClientById(clientId) : null;
    const details = document.getElementById('sector-details');

    if (details) {
      details.classList.remove('hidden');
      if (client) {
        const ltv = store.getClientLTV(client.id);
        const avgCatch = store.getClientAvgCatch(client.id);
        const badge = store.getLevelBadge(client.level);
        const booking = BOOKINGS.find(b => b.sectorId === parseInt(sectorId));
        const block = booking ? TIME_BLOCKS.find(tb => tb.id === booking.blockId) : null;
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
          ${booking && block ? `<div style="font-size:12px;color:var(--kMuted);margin-bottom:12px;">${block.icon} ${booking.date} · ${block.time}</div>` : ''}
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
        document.getElementById('sector-client-link')?.addEventListener('click', () => {
          showClientCard(client.id, parseInt(sectorId));
        });
      } else {
        details.innerHTML = `
          <div class="card-header">
            <div class="card-title">Сектор ${sectorId}</div>
            <span style="font-size:11px;padding:4px 8px;background:rgba(63,166,107,0.12);color:#3FA66B;border-radius:50%;font-weight:700;">Свободен</span>
          </div>
          <p style="color:var(--kMuted2);font-size:13px;">Сектор пуст. Назначить клиента можно через экран Чек.</p>
        `;
      }
    }
  });
}
