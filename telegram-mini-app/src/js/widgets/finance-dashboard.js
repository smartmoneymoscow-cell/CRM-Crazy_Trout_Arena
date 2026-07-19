// === FinanceDashboardCard (точь-в-точь Flutter finance_dashboard_card.dart) ===
// ┌───────────────────────┬──┬───────────────┐
// │  Выручка (тёмная,     │  │ Маржинальная  │
// │  большая) + спарклайн │)( │ прибыль       │
// │                       │  ├───────────────┤
// │                       │  │ Переменные    │
// │                       │  │ расходы       │
// └───────────────────────┴──┴───────────────┘

import { drawSparkline } from './charts.js';

export function renderFinanceDashboardCard(container, stats) {
  const isUp = stats.revenueDeltaPct >= 0;
  const deltaSign = isUp ? '+' : '';
  const deltaColor = isUp ? '#4F9D75' : '#E15C4D';

  container.innerHTML = '';
  container.style.cssText = `
    background: #F3EFE7;
    border-radius: 18px;
    padding: 16px;
    margin-bottom: 14px;
  `;

  const row = document.createElement('div');
  row.style.cssText = 'display:flex;height:200px;gap:0;';

  // ── Левая карточка: Выручка + спарклайн ──
  const leftCard = document.createElement('div');
  leftCard.style.cssText = `
    flex:1;
    border-radius:20px;
    background:linear-gradient(-30deg, #131211 70%, #1D1B18 100%);
    padding:18px;
    display:flex;
    flex-direction:column;
    justify-content:space-between;
    position:relative;
    overflow:hidden;
  `;
  // Декоративное свечение
  const glow = document.createElement('div');
  glow.style.cssText = `
    position:absolute;top:-30px;right:-30px;width:110px;height:110px;
    border-radius:50%;
    background:radial-gradient(circle, rgba(232,145,43,0.20) 0%, rgba(232,145,43,0) 70%);
  `;
  leftCard.appendChild(glow);

  const leftContent = document.createElement('div');
  leftContent.style.cssText = 'position:relative;z-index:1;display:flex;flex-direction:column;justify-content:space-between;height:100%;';
  leftContent.innerHTML = `
    <div>
      <div style="color:#EFE9DF;font-size:13px;font-weight:600;">Выручка</div>
      <div style="margin-top:12px;color:#E8912B;font-size:21px;font-weight:800;letter-spacing:-0.3px;">${formatMoney(stats.revenue)} ₽</div>
      <div style="margin-top:10px;color:${deltaColor};font-size:13px;font-weight:700;">${deltaSign}${stats.revenueDeltaPct.toFixed(1).replace('.', ',')}%</div>
      <div style="margin-top:2px;color:#8B8579;font-size:10.5px;">к прошлому периоду</div>
    </div>
    <div style="height:44px;width:100%;" id="fd-sparkline"></div>
  `;
  leftCard.appendChild(leftContent);

  // ── Скоба-разделитель (как Flutter _BracePainter) ──
  const brace = document.createElement('div');
  brace.style.cssText = 'width:22px;flex-shrink:0;display:flex;align-items:center;justify-content:center;overflow:hidden;';
  brace.innerHTML = `<svg width="22" height="100%" viewBox="0 0 28 400" preserveAspectRatio="none" fill="none" xmlns="http://www.w3.org/2000/svg">
    <path d="M28 0 C22 0 16 0 14 12 C12 24 14 24 14 40 L14 160 C14 170 8 180 0 200 C8 220 14 230 14 240 L14 360 C14 376 22 400 28 400" stroke="#C9BFA9" stroke-width="1.2" fill="none" opacity="0.7"/>
    <circle cx="0" cy="200" r="2.5" fill="#C9BFA9" opacity="0.5"/>
  </svg>`;

  // ── Правая колонка: Маржа + Расходы ──
  const rightCol = document.createElement('div');
  rightCol.style.cssText = 'flex:1;display:flex;flex-direction:column;';

  // Маржинальная прибыль (зелёная карточка)
  const marginCard = document.createElement('div');
  marginCard.style.cssText = `
    flex:1;
    background:#F0F7F2;
    border-radius:16px 16px 0 0;
    padding:14px 14px 12px;
    display:flex;
    flex-direction:column;
  `;
  marginCard.innerHTML = `
    <div style="color:#7A7266;font-size:11px;font-weight:700;">Маржинальная</div>
    <div style="color:#B7B0A2;font-size:10px;font-weight:500;">прибыль</div>
    <div style="margin-top:8px;color:#2E7D4F;font-size:15px;font-weight:800;letter-spacing:-0.2px;">${formatMoney(stats.marginProfit)} ₽</div>
    <div style="margin-top:2px;color:#A49C8D;font-size:9.5px;font-weight:600;">${stats.marginPct.toFixed(1).replace('.', ',')}% маржинальность</div>
    <div style="flex:1;"></div>
    <div style="height:6px;border-radius:3px;background:#E1DCCF;overflow:hidden;">
      <div style="height:100%;width:${Math.min(stats.marginPct, 100)}%;background:linear-gradient(90deg,#2F8F5B,#4CAF7D);border-radius:3px;"></div>
    </div>
  `;

  // Переменные расходы (тёмная карточка)
  const expenseCard = document.createElement('div');
  expenseCard.style.cssText = `
    flex:1;
    background:linear-gradient(-30deg, #170B0A 70%, #2C1613 100%);
    border-radius:0 0 16px 16px;
    padding:14px 14px 12px;
    display:flex;
    flex-direction:column;
  `;
  expenseCard.innerHTML = `
    <div style="color:#F0D9D3;font-size:11px;font-weight:700;">Переменные</div>
    <div style="color:#A97B71;font-size:10px;font-weight:500;">расходы</div>
    <div style="margin-top:8px;color:#E2604C;font-size:15px;font-weight:800;letter-spacing:-0.2px;">${formatMoney(stats.variableExpenses)} ₽</div>
    <div style="margin-top:2px;color:#B98077;font-size:9.5px;font-weight:600;">${stats.expensesPct.toFixed(1).replace('.', ',')}%<br>от выручки</div>
    <div style="flex:1;"></div>
    <div style="height:6px;border-radius:3px;background:#4A2B26;overflow:hidden;">
      <div style="height:100%;width:${Math.min(stats.expensesPct, 100)}%;background:linear-gradient(90deg,#C0392B,#E15C4D);border-radius:3px;"></div>
    </div>
  `;

  rightCol.appendChild(marginCard);
  rightCol.appendChild(expenseCard);

  row.appendChild(leftCard);
  row.appendChild(brace);
  row.appendChild(rightCol);
  container.appendChild(row);

  // Спарклайн (Canvas)
  setTimeout(() => {
    const sparkContainer = container.querySelector('#fd-sparkline');
    if (sparkContainer && stats.sparkline?.length) {
      const canvas = document.createElement('canvas');
      canvas.style.cssText = 'width:100%;height:100%;display:block;';
      sparkContainer.appendChild(canvas);
      drawSparkline(canvas, stats.sparkline.map(v => v * 100));
    }
  }, 0);
}

function formatMoney(v) {
  const s = Math.round(v).toString();
  let buf = '';
  for (let i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 === 0) buf += ' ';
    buf += s[i];
  }
  return buf;
}
