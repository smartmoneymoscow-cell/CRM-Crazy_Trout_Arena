// === Screen: Карта пруда (точь-в-точь Flutter pond_map_screen.dart) ===
import { store } from '../core/store.js';
import { tg } from '../core/telegram.js';
import { showClientCard } from '../widgets/client-card.js';
import { showCalendarPicker } from '../widgets/calendar.js';
import { createFilterDropdown } from '../widgets/filter-dropdown.js';

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

    <!-- Пруд с Canvas-рендерингом (как Flutter CustomPainter) -->
    <div id="pond-canvas-wrap" style="position:relative;margin-bottom:16px;border-radius:16px;overflow:hidden;">
      <canvas id="pond-canvas" style="width:100%;display:block;"></canvas>
      <!-- Фильтры ВНУТРИ сцены (как Flutter FilterDropdown) -->
      <div id="pond-filters" style="position:absolute;top:12px;left:12px;right:12px;z-index:3;max-width:200px;"></div>
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

  setTimeout(async () => {
    await loadTextures();
    renderPondCanvas();
    renderSectorMarkers();
    renderBookingFeed();
    initPondHandlers();
  }, 0);
  return el;
}

// ─── Загрузка текстур (из Flutter base64) ───
const _treeImages = [];
let _grassTile = null;
let _texturesLoaded = false;

function loadTextures() {
  if (_texturesLoaded) return Promise.resolve();
  const sources = [
    'src/assets/textures/treemain.png',
    'src/assets/textures/treeextra0.png',
    'src/assets/textures/treeextra1.png',
    'src/assets/textures/treeextra2.png',
  ];
  return Promise.all(sources.map(src => new Promise((resolve) => {
    const img = new Image();
    img.onload = () => { _treeImages.push(img); resolve(); };
    img.onerror = () => { _treeImages.push(null); resolve(); };
    img.src = src;
  }))).then(() => {
    return new Promise((resolve) => {
      const img = new Image();
      img.onload = () => { _grassTile = img; resolve(); };
      img.onerror = () => resolve();
      img.src = 'src/assets/textures/grasstile.png';
    });
  }).then(() => { _texturesLoaded = true; });
}

// ─── Forest spots (точь-в-точь Flutter _forestSpots) ───
const _forestSpots = [
  [0.05, 0.045, 0, 0.62], [0.15, 0.03, 1, 0.7], [0.26, 0.045, 2, 0.56], [0.37, 0.028, 3, 0.68],
  [0.63, 0.03, 0, 0.63], [0.74, 0.045, 1, 0.7], [0.85, 0.03, 2, 0.58], [0.95, 0.045, 3, 0.68],
  [0.05, 0.955, 0, 0.65], [0.16, 0.97, 1, 0.56], [0.28, 0.955, 2, 0.7], [0.4, 0.97, 3, 0.62],
  [0.6, 0.955, 0, 0.65], [0.72, 0.97, 1, 0.56], [0.84, 0.955, 2, 0.72], [0.95, 0.97, 3, 0.63],
  [0.018, 0.16, 0, 0.62], [0.014, 0.3, 1, 0.56], [0.014, 0.44, 2, 0.65], [0.014, 0.58, 3, 0.56],
  [0.014, 0.72, 0, 0.63], [0.018, 0.86, 1, 0.56],
  [0.982, 0.16, 2, 0.62], [0.986, 0.3, 3, 0.56], [0.986, 0.44, 0, 0.68], [0.986, 0.58, 1, 0.58],
  [0.986, 0.72, 2, 0.65], [0.982, 0.86, 3, 0.56],
];

// ─── Lily data (точь-в-точь Flutter _lilies) ───
function getLilies(W, H) {
  return [
    { x: W * 0.50 - 118, y: H * 0.50 - 70, r: 15 },
    { x: W * 0.50 + 96, y: H * 0.50 - 40, r: 12 },
    { x: W * 0.50 - 40, y: H * 0.50 + 100, r: 13 },
    { x: W * 0.50 + 130, y: H * 0.50 + 60, r: 10 },
    { x: W * 0.50 - 150, y: H * 0.50 + 20, r: 9 },
  ];
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

  const cx = W / 2, cy = H / 2;

  // ── 1. Фон-трава (градиент как Flutter) ──
  const grassGrad = ctx.createRadialGradient(cx, cy * 0.52, 0, cx, cy, W * 0.78);
  grassGrad.addColorStop(0, '#548F5F');
  grassGrad.addColorStop(0.45, '#3F7C4A');
  grassGrad.addColorStop(1, '#2A5533');
  ctx.fillStyle = grassGrad;
  ctx.fillRect(0, 0, W, H);

  // ── 2. Текстура травы (tile pattern, как Flutter ImageShader) ──
  if (_grassTile) {
    ctx.save();
    ctx.globalAlpha = 0.55;
    try {
      const pattern = ctx.createPattern(_grassTile, 'repeat');
      if (pattern) {
        ctx.fillStyle = pattern;
        ctx.fillRect(0, 0, W, H);
      }
    } catch (e) {}
    ctx.restore();
    // Второй слой градиента поверх
    ctx.save();
    ctx.globalAlpha = 0.35;
    ctx.fillStyle = grassGrad;
    ctx.fillRect(0, 0, W, H);
    ctx.restore();
  }

  // ── 3. Деревья (4 варианта текстур, 28 точек, рандомный поворот) ──
  _forestSpots.forEach((s, i) => {
    const treeCx = s[0] * W, treeCy = s[1] * H;
    const imgIdx = Math.round(s[2]);
    const treeSize = 92 * s[3];
    const img = _treeImages.length > imgIdx ? _treeImages[imgIdx] : null;
    if (!img) return;
    const rot = ((i * 47) % 360) * Math.PI / 180;

    // Тень под деревом
    ctx.fillStyle = 'rgba(0,0,0,0.16)';
    ctx.beginPath();
    ctx.ellipse(treeCx, treeCy + treeSize * 0.36, treeSize * 0.36, treeSize * 0.12, 0, 0, Math.PI * 2);
    ctx.fill();

    // Рисунок дерева с поворотом
    ctx.save();
    ctx.translate(treeCx, treeCy);
    ctx.rotate(rot);
    ctx.drawImage(img, -treeSize / 2, -treeSize / 2, treeSize, treeSize);
    ctx.restore();
  });

  // ── 4. Сплайн пруда ──
  const splinePts = catmullRomSpline(getPondSplinePoints(W, H));

  // ── 5. Берег/дорожка (градиент как Flutter) ──
  ctx.beginPath();
  splinePts.forEach((p, i) => i === 0 ? ctx.moveTo(p.x, p.y) : ctx.lineTo(p.x, p.y));
  ctx.closePath();
  const bankGrad = ctx.createLinearGradient(0, 0, W, H);
  bankGrad.addColorStop(0, '#E4C486');
  bankGrad.addColorStop(0.55, '#CE9F57');
  bankGrad.addColorStop(1, '#B4874A');
  ctx.fillStyle = bankGrad;
  ctx.fill();
  // Рамка берега
  ctx.strokeStyle = 'rgba(0,0,0,0.13)';
  ctx.lineWidth = 1;
  ctx.stroke();

  // ── 6. Кусты между секторами (как Flutter _drawBush) ──
  const bushDarkTones = ['#2E5C38', '#3B6E42', '#356749'];
  const bushMidTones = ['#4C8A58', '#57935F', '#4E8A5A'];
  function drawBush(ox, oy, scale, tone) {
    const dark = bushDarkTones[tone % 3];
    const mid = bushMidTones[tone % 3];
    ctx.save();
    ctx.translate(ox, oy);
    ctx.scale(scale, scale);
    // Тень
    ctx.fillStyle = 'rgba(0,0,0,0.10)';
    ctx.beginPath(); ctx.ellipse(0, 10, 34, 9, 0, 0, Math.PI * 2); ctx.fill();
    // Круги куста
    ctx.fillStyle = dark; ctx.beginPath(); ctx.arc(-16, 0, 17, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = mid; ctx.beginPath(); ctx.arc(10, -6, 20, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = dark; ctx.beginPath(); ctx.arc(20, 6, 14, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = mid; ctx.beginPath(); ctx.arc(-2, 8, 15, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = 'rgba(99,164,104,0.85)'; ctx.beginPath(); ctx.arc(4, -10, 10, 0, Math.PI * 2); ctx.fill();
    ctx.restore();
  }
  // Позиции кустов (между секторами, как Flutter _midBankPoint)
  function midBankPoint(n1, n2, push = 6) {
    const p1 = getSectorPosition(n1, W, H), p2 = getSectorPosition(n2, W, H);
    if (!p1 || !p2) return null;
    const mx = (p1.x + p2.x) / 2, my = (p1.y + p2.y) / 2;
    const dx = mx - cx, dy = my - cy;
    const len = Math.sqrt(dx * dx + dy * dy);
    const k = len === 0 ? 0 : push / len;
    return { x: mx + dx * k, y: my + dy * k };
  }
  const bushPositions = [
    { n1: 2, n2: 3, s: 0.6, t: 1 }, { n1: 6, n2: 7, s: 0.55, t: 0 },
    { n1: 11, n2: 12, s: 0.6, t: 2 }, { n1: 14, n2: 15, s: 0.52, t: 1 },
  ];
  bushPositions.forEach(({ n1, n2, s, t }) => {
    const p = midBankPoint(n1, n2);
    if (p) drawBush(p.x, p.y, s, t);
  });

  // ── 7. Тростник (как Flutter _drawReedTuft — квадратичные кривые) ──
  function drawReedTuft(ox, oy, scale) {
    ctx.save();
    ctx.translate(ox, oy);
    ctx.scale(scale, scale);
    ctx.strokeStyle = '#3C6B34';
    ctx.lineWidth = 2.4;
    ctx.lineCap = 'round';
    function stem(c1x, c1y, ex, ey) {
      ctx.beginPath(); ctx.moveTo(0, 0);
      ctx.quadraticCurveTo(c1x, c1y, ex, ey);
      ctx.stroke();
    }
    stem(-2, -18, -10, -40);
    stem(5, -22, 2, -46);
    stem(12, -16, 22, -34);
    stem(-8, -14, -20, -28);
    // Цветок на конце
    ctx.fillStyle = '#6B5A2E';
    ctx.beginPath(); ctx.arc(2, -46, 2.6, 0, Math.PI * 2); ctx.fill();
    ctx.restore();
  }
  const reedPositions = [
    { n1: 4, n2: 5, s: 0.75 }, { n1: 12, n2: 13, s: 0.7 }, { n1: 15, n2: 16, s: 0.68 },
  ];
  reedPositions.forEach(({ n1, n2, s }) => {
    const p = midBankPoint(n1, n2);
    if (p) drawReedTuft(p.x, p.y, s);
  });
  // Дополнительные тростники у берега
  drawReedTuft(cx - 150, cy - 150, 0.55);
  drawReedTuft(cx + 170, cy - 120, 0.5);

  // ── 8. Вода (градиент + клип по сплайну) ──
  ctx.save();
  ctx.beginPath();
  splinePts.forEach((p, i) => i === 0 ? ctx.moveTo(p.x, p.y) : ctx.lineTo(p.x, p.y));
  ctx.closePath();
  ctx.clip();

  const waterGrad = ctx.createRadialGradient(cx * 0.76, cy * 0.64, W * 0.05, cx, cy, W * 0.75);
  waterGrad.addColorStop(0, '#4AA0C6');
  waterGrad.addColorStop(0.35, '#2A7E9E');
  waterGrad.addColorStop(0.7, '#186286');
  waterGrad.addColorStop(1, '#0F4C6C');
  ctx.fillStyle = waterGrad;
  ctx.fillRect(0, 0, W, H);

  // Блики (как Flutter)
  const hlGrad1 = ctx.createRadialGradient(cx - 70, cy - 90, 0, cx - 70, cy - 90, 160);
  hlGrad1.addColorStop(0, 'rgba(255,255,255,0.5)');
  hlGrad1.addColorStop(1, 'rgba(255,255,255,0)');
  ctx.fillStyle = hlGrad1;
  ctx.beginPath(); ctx.ellipse(cx - 70, cy - 90, 160, 70, 0, 0, Math.PI * 2); ctx.fill();

  ctx.fillStyle = 'rgba(255,255,255,0.05)';
  ctx.beginPath(); ctx.ellipse(cx + 120, cy + 60, 90, 40, 0, 0, Math.PI * 2); ctx.fill();

  // Рябь
  ctx.strokeStyle = 'rgba(255,255,255,0.12)';
  ctx.lineWidth = 1;
  [[cx - 30, cy + 130, 70, 6], [cx + 40, cy + 130, 60, 6], [cx + 110, cy + 130, 50, 6]].forEach(([rx, ry, rw, rh]) => {
    ctx.beginPath(); ctx.ellipse(rx, ry, rw, rh, 0, 0, Math.PI * 2); ctx.stroke();
  });

  // Кувшинки (точь-в-точь Flutter _drawLilyPad)
  getLilies(W, H).forEach(l => {
    // Тень
    ctx.fillStyle = 'rgba(14,58,80,0.35)';
    ctx.beginPath(); ctx.ellipse(l.x + 1.5, l.y + 2, l.r, l.r * 0.62, 0, 0, Math.PI * 2); ctx.fill();
    // Лист
    ctx.save();
    ctx.translate(l.x, l.y);
    ctx.rotate(18 * Math.PI / 180);
    ctx.fillStyle = '#3E8F52';
    ctx.beginPath(); ctx.arc(0, 0, l.r, 0, Math.PI * 2); ctx.fill();
    // Линия на листе
    ctx.strokeStyle = 'rgba(44,107,60,0.6)';
    ctx.lineWidth = 1.4;
    ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(l.r * 0.85, 0); ctx.stroke();
    ctx.restore();
    // Цветок (если r > 11)
    if (l.r > 11) {
      ctx.fillStyle = 'rgba(244,227,232,0.9)';
      ctx.beginPath(); ctx.arc(l.x - l.r * 0.15, l.y - l.r * 0.05, l.r * 0.16, 0, Math.PI * 2); ctx.fill();
    }
  });

  ctx.restore(); // clip

  // Рамка воды
  ctx.strokeStyle = 'rgba(10,58,84,0.4)';
  ctx.lineWidth = 1.5;
  ctx.beginPath();
  splinePts.forEach((p, i) => i === 0 ? ctx.moveTo(p.x, p.y) : ctx.lineTo(p.x, p.y));
  ctx.closePath();
  ctx.stroke();

  // ── 9. Удочки у занятых секторов (как Flutter _drawFishingRod) ──
  store.sectors.filter(s => s.occupied).forEach(s => {
    const marker = getSectorPosition(s.id, W, H);
    if (!marker) return;
    const dx = cx - marker.x, dy = cy - marker.y;
    const len = Math.sqrt(dx * dx + dy * dy);
    if (len === 0) return;
    const ux = dx / len, uy = dy / len;
    const markerR = 20;
    const bankX = marker.x + ux * (markerR + 6);
    const bankY = marker.y + uy * (markerR + 6);
    const tipX = marker.x + ux * (markerR + 26) + (-uy) * 10;
    const tipY = marker.y + uy * (markerR + 26) + ux * 10 - 14;
    const floatX = marker.x + ux * (len * 0.4);
    const floatY = marker.y + uy * (len * 0.4);

    // Удилище
    ctx.strokeStyle = '#7A5533';
    ctx.lineWidth = 2.4;
    ctx.lineCap = 'round';
    ctx.beginPath(); ctx.moveTo(bankX, bankY); ctx.lineTo(tipX, tipY); ctx.stroke();
    // Леска
    ctx.strokeStyle = 'rgba(237,230,214,0.85)';
    ctx.lineWidth = 1;
    ctx.beginPath(); ctx.moveTo(tipX, tipY); ctx.lineTo(floatX, floatY); ctx.stroke();
    // Рябь вокруг поплавка
    ctx.strokeStyle = 'rgba(220,239,246,0.35)';
    ctx.beginPath(); ctx.arc(floatX, floatY, 9, 0, Math.PI * 2); ctx.stroke();
    ctx.strokeStyle = 'rgba(220,239,246,0.2)';
    ctx.beginPath(); ctx.arc(floatX, floatY, 14, 0, Math.PI * 2); ctx.stroke();
    // Поплавок
    ctx.fillStyle = '#fff';
    ctx.beginPath(); ctx.arc(floatX, floatY, 3.6, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#D6412E';
    ctx.beginPath(); ctx.arc(floatX, floatY, 3.6, Math.PI, Math.PI * 2); ctx.fill();
  });
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
        <span style="font-size:7px;color:rgba(255,255,255,0.8);line-height:1;">${isOccupied ? (client ? store.getClientInitials(client) : '<svg width="8" height="8" viewBox="0 0 24 24" fill="white"><path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>') : 'Своб.'}</span>
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
  // FilterDropdown (как Flutter FilterDropdown с Правилом 5)
  const filtersContainer = document.getElementById('pond-filters');
  if (filtersContainer) {
    createFilterDropdown(filtersContainer, {
      value: null,
      label: 'Нет',
      items: [
        { value: null, label: 'Нет', isReset: true, enabled: true },
        { value: 'all', label: 'Все клиенты' },
        { value: 'premium', label: 'Премиум' },
        { value: 'standard', label: 'Стандарт' },
        { value: 'basic', label: 'Базовый' },
      ],
      onChanged: (v) => {
        currentFilter = v || 'none';
        renderSectorMarkers();
        tg.hapticSelection();
      },
    });
  }

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
