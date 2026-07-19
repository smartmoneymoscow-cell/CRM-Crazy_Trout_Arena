// === Кастомные Canvas-графики (как Flutter FinanceDashboardCard, FinancePieChart и т.д.) ===
// Без Chart.js — чистый Canvas 2D, точные цвета и пропорции из Flutter.

// ─── Sparkline (как Flutter FinanceDashboardCard) ───
export function drawSparkline(canvas, data, options = {}) {
  const { color = '#E8912B', fill = 'rgba(232,145,43,0.15)', lineWidth = 2 } = options;
  const ctx = canvas.getContext('2d');
  const w = canvas.width = canvas.offsetWidth * 2;
  const h = canvas.height = canvas.offsetHeight * 2;
  ctx.scale(2, 2);
  const dw = canvas.offsetWidth;
  const dh = canvas.offsetHeight;

  if (!data.length) return;
  const max = Math.max(...data, 1);
  const min = Math.min(...data, 0);
  const range = max - min || 1;
  const step = dw / (data.length - 1);

  const points = data.map((v, i) => ({
    x: i * step,
    y: dh - ((v - min) / range) * (dh - 4) - 2,
  }));

  // Fill
  ctx.beginPath();
  ctx.moveTo(points[0].x, dh);
  points.forEach(p => ctx.lineTo(p.x, p.y));
  ctx.lineTo(points[points.length - 1].x, dh);
  ctx.closePath();
  ctx.fillStyle = fill;
  ctx.fill();

  // Line
  ctx.beginPath();
  ctx.moveTo(points[0].x, points[0].y);
  for (let i = 1; i < points.length; i++) {
    const cp1x = (points[i - 1].x + points[i].x) / 2;
    ctx.bezierCurveTo(cp1x, points[i - 1].y, cp1x, points[i].y, points[i].x, points[i].y);
  }
  ctx.strokeStyle = color;
  ctx.lineWidth = lineWidth;
  ctx.stroke();
}

// ─── Doughnut chart (как Flutter FinancePieChart) ───
export function drawDoughnut(canvas, labels, data, colors, options = {}) {
  const { cutout = 0.6, legendPosition = 'right' } = options;
  const ctx = canvas.getContext('2d');
  const dpr = 2;
  const w = canvas.offsetWidth;
  const h = canvas.offsetHeight;
  canvas.width = w * dpr;
  canvas.height = h * dpr;
  ctx.scale(dpr, dpr);

  const total = data.reduce((s, v) => s + v, 0) || 1;
  const cx = legendPosition === 'right' ? h / 2 : w / 2;
  const cy = h / 2;
  const r = Math.min(cx, cy) - 4;
  const innerR = r * cutout;

  let angle = -Math.PI / 2;
  data.forEach((v, i) => {
    const sliceAngle = (v / total) * Math.PI * 2;
    ctx.beginPath();
    ctx.arc(cx, cy, r, angle, angle + sliceAngle);
    ctx.arc(cx, cy, innerR, angle + sliceAngle, angle, true);
    ctx.closePath();
    ctx.fillStyle = colors[i % colors.length];
    ctx.fill();
    angle += sliceAngle;
  });

  // Легенда
  if (legendPosition === 'right') {
    const lx = h + 16;
    ctx.font = '11px Roboto, sans-serif';
    ctx.textBaseline = 'middle';
    labels.forEach((label, i) => {
      const y = 16 + i * 20;
      ctx.fillStyle = colors[i % colors.length];
      ctx.fillRect(lx, y - 4, 10, 10);
      ctx.fillStyle = '#14130F';
      ctx.fillText(label, lx + 16, y + 1);
    });
  }
}

// ─── Line chart (как Flutter RevenueDynamicsChart) ───
export function drawLineChart(canvas, labels, data, options = {}) {
  const { color = '#E8912B', fill = 'rgba(232,145,43,0.1)', pointRadius = 4, showGrid = true } = options;
  const ctx = canvas.getContext('2d');
  const dpr = 2;
  const w = canvas.offsetWidth;
  const h = canvas.offsetHeight;
  canvas.width = w * dpr;
  canvas.height = h * dpr;
  ctx.scale(dpr, dpr);

  const padding = { top: 16, right: 16, bottom: 32, left: 50 };
  const chartW = w - padding.left - padding.right;
  const chartH = h - padding.top - padding.bottom;

  if (!data.length) return;
  const max = Math.max(...data, 1);
  const min = 0;
  const range = max - min || 1;
  const step = chartW / (data.length - 1);

  const points = data.map((v, i) => ({
    x: padding.left + i * step,
    y: padding.top + chartH - ((v - min) / range) * chartH,
  }));

  // Grid + Y labels
  if (showGrid) {
    ctx.strokeStyle = '#E7E0D1';
    ctx.lineWidth = 0.5;
    ctx.font = '10px Roboto, sans-serif';
    ctx.fillStyle = '#9C9484';
    ctx.textAlign = 'right';
    for (let i = 0; i <= 4; i++) {
      const y = padding.top + (chartH / 4) * i;
      const val = Math.round(max - (max / 4) * i);
      ctx.beginPath();
      ctx.moveTo(padding.left, y);
      ctx.lineTo(w - padding.right, y);
      ctx.stroke();
      ctx.fillText(val.toLocaleString('ru-RU'), padding.left - 8, y + 3);
    }
  }

  // X labels
  ctx.textAlign = 'center';
  ctx.fillStyle = '#9C9484';
  ctx.font = '10px Roboto, sans-serif';
  labels.forEach((label, i) => {
    ctx.fillText(label, points[i].x, h - 8);
  });

  // Fill area
  ctx.beginPath();
  ctx.moveTo(points[0].x, padding.top + chartH);
  points.forEach(p => ctx.lineTo(p.x, p.y));
  ctx.lineTo(points[points.length - 1].x, padding.top + chartH);
  ctx.closePath();
  ctx.fillStyle = fill;
  ctx.fill();

  // Line
  ctx.beginPath();
  ctx.moveTo(points[0].x, points[0].y);
  for (let i = 1; i < points.length; i++) {
    const cp1x = (points[i - 1].x + points[i].x) / 2;
    ctx.bezierCurveTo(cp1x, points[i - 1].y, cp1x, points[i].y, points[i].x, points[i].y);
  }
  ctx.strokeStyle = color;
  ctx.lineWidth = 2;
  ctx.stroke();

  // Points
  points.forEach(p => {
    ctx.beginPath();
    ctx.arc(p.x, p.y, pointRadius, 0, Math.PI * 2);
    ctx.fillStyle = color;
    ctx.fill();
    ctx.strokeStyle = '#FFFFFF';
    ctx.lineWidth = 2;
    ctx.stroke();
  });
}
