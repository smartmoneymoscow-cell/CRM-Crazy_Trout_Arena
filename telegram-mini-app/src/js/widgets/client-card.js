// === Client Card Modal (точь-в-точь Flutter _ClientCard) ===
// Градиентный хедер, медаль, progress bar лояльности, статистика.

import { store } from '../core/store.js';

const LEVEL_COLORS = {
  premium:  { color: '#B8862E', top: '#FFE18A', mid: '#E0A62E', bottom: '#AD7A16', letter: '#4A3300' },
  standard: { color: '#8B94A0', top: '#F2F5F8', mid: '#C9D1D9', bottom: '#98A2AD', letter: '#2E3438' },
  basic:    { color: '#8C5C34', top: '#E3B98B', mid: '#C08A54', bottom: '#8C5C34', letter: '#FFFFFF' },
};

function formatLtv(ltvK) {
  if (ltvK >= 1000) return (ltvK / 1000).toFixed(1).replace('.', ',') + ' млн';
  if (ltvK >= 1) return ltvK.toFixed(1).replace('.', ',') + ' тыс';
  return ltvK + '';
}

export function showClientCard(clientId, sectorId) {
  const client = store.getClientById(clientId);
  if (!client) return;

  const l = LEVEL_COLORS[client.level] || LEVEL_COLORS.basic;
  const badge = store.getLevelBadge(client.level);
  const ltv = store.getClientLTV(client.id);
  const avgCatch = store.getClientAvgCatch(client.id);
  const pct = Math.min(Math.round((client.points / client.pointsNext) * 100), 100);

  const overlay = document.createElement('div');
  overlay.className = 'modal-overlay';
  overlay.innerHTML = `
    <div style="
      margin:20px;
      max-width:340px;
      width:calc(100% - 40px);
      background:#FBF6EC;
      border-radius:22px;
      box-shadow:0 24px 60px rgba(0,0,0,0.35);
      overflow:hidden;
    ">
      <!-- Header с градиентом уровня -->
      <div style="
        padding:22px 20px 18px;
        background:linear-gradient(135deg, ${l.color}, #14130F);
        position:relative;
      ">
        <div style="display:flex;align-items:center;gap:14px;">
          ${store.renderAvatar(client, 60)}
          <div style="flex:1;">
            <div style="color:#fff;font-size:17px;font-weight:800;">${client.name}</div>
            <div style="margin-top:6px;display:flex;align-items:center;">
              <span style="
                display:inline-flex;align-items:center;justify-content:center;
                width:28px;height:28px;border-radius:50%;
                background:linear-gradient(135deg,${l.top},${l.mid},${l.bottom});
                border:2px solid ${l.color};
                color:${l.letter};font-size:12px;font-weight:700;
                box-shadow:0 2px 6px ${l.color}66;
              ">${badge.letter}</span>
              <span style="color:rgba(255,255,255,0.7);font-size:12px;margin-left:6px;">${badge.label}</span>
            </div>
          </div>
        </div>
        <!-- Points progress -->
        <div style="margin-top:14px;">
          <div style="display:flex;justify-content:space-between;font-size:11px;color:rgba(255,255,255,0.5);">
            <span>${client.points} баллов</span>
            <span>${client.pointsNext} для следующего уровня</span>
          </div>
          <div style="height:7px;border-radius:999px;background:rgba(255,255,255,0.15);margin-top:4px;overflow:hidden;">
            <div style="height:100%;width:${pct}%;background:linear-gradient(90deg,${l.top},${l.mid});border-radius:999px;"></div>
          </div>
        </div>
        <!-- Кнопка закрытия в правом верхнем углу -->
        <button id="client-card-close" style="
          position:absolute;top:0;right:0;
          width:28px;height:28px;border-radius:50%;
          background:rgba(255,255,255,0.18);border:none;
          display:flex;align-items:center;justify-content:center;
          cursor:pointer;color:#fff;font-size:16px;
        ">✕</button>
      </div>

      <!-- Body -->
      <div style="padding:18px 20px 20px;">
        <!-- Телефон + Email + Сейчас на секторе -->
        <div style="display:flex;align-items:flex-start;gap:12px;margin-bottom:16px;">
          <div style="flex:1;">
            <div style="display:flex;align-items:center;gap:8px;margin-bottom:8px;">
              <span style="color:#E8912B;font-size:15px;">📞</span>
              <span style="font-size:13px;color:#2D2D2D;">${client.phone}</span>
            </div>
            <div style="display:flex;align-items:center;gap:8px;">
              <span style="color:#E8912B;font-size:15px;">✉️</span>
              <span style="font-size:13px;color:#2D2D2D;">${client.email || 'Нет email'}</span>
            </div>
          </div>
          ${sectorId ? `
            <div style="text-align:center;">
              <div style="font-size:9.5px;font-weight:700;color:rgba(0,0,0,0.45);letter-spacing:0.3px;">СЕЙЧАС НА СЕКТОРЕ</div>
              <div style="font-size:15px;font-weight:800;color:#E8912B;margin-top:2px;">№ ${sectorId}</div>
            </div>
          ` : ''}
        </div>

        <!-- Баллы лояльности (прогресс-бар) -->
        <div style="
          padding:12px 14px;
          background:#fff;border-radius:14px;
          border:0.5px solid #E7E0D1;
          margin-bottom:14px;
        ">
          <div style="display:flex;justify-content:space-between;margin-bottom:6px;">
            <span style="font-size:11px;font-weight:700;color:rgba(0,0,0,0.54);">БАЛЛЫ ЛОЯЛЬНОСТИ</span>
            <span style="font-size:11px;font-weight:700;color:${l.color};">${client.points} / ${client.pointsNext}</span>
          </div>
          <div style="height:7px;border-radius:999px;background:#EFE9DC;overflow:hidden;">
            <div style="height:100%;width:${pct}%;background:${l.color};border-radius:999px;"></div>
          </div>
        </div>

        <!-- Сетка статов 2×2 -->
        <div style="display:grid;grid-template-columns:repeat(2,1fr);gap:10px;margin-bottom:10px;">
          <div style="padding:9px 11px;background:#fff;border-radius:12px;border:0.5px solid #E7E0D1;">
            <div style="font-size:10.5px;font-weight:700;color:rgba(0,0,0,0.45);letter-spacing:0.3px;">Тариф</div>
            <div style="font-size:14px;font-weight:800;color:#2D2D2D;margin-top:3px;">${client.tariff === 'standard' ? 'Стандарт' : client.tariff === 'pensioner' ? 'Пенсионер' : 'Гостевой'}</div>
          </div>
          <div style="padding:9px 11px;background:#fff;border-radius:12px;border:0.5px solid #E7E0D1;">
            <div style="font-size:10.5px;font-weight:700;color:rgba(0,0,0,0.45);letter-spacing:0.3px;">Посещений / LTV</div>
            <div style="font-size:14px;font-weight:800;color:#2D2D2D;margin-top:3px;">${client.visits} / ${formatLtv(ltv)} ₽</div>
          </div>
          <div style="padding:9px 11px;background:#fff;border-radius:12px;border:0.5px solid #E7E0D1;">
            <div style="font-size:10.5px;font-weight:700;color:rgba(0,0,0,0.45);letter-spacing:0.3px;">Всего поймано рыб</div>
            <div style="font-size:14px;font-weight:800;color:#2D2D2D;margin-top:3px;">${client.fish || 0} шт. / ${avgCatch.totalWeight || 0} кг.</div>
          </div>
          <div style="padding:9px 11px;background:#fff;border-radius:12px;border:0.5px solid #E7E0D1;">
            <div style="font-size:10.5px;font-weight:700;color:rgba(0,0,0,0.45);letter-spacing:0.3px;">Первый визит</div>
            <div style="font-size:14px;font-weight:800;color:#2D2D2D;margin-top:3px;">${client.firstVisit || 'Н/Д'}</div>
          </div>
        </div>

        <!-- Лучший улов -->
        ${client.bestCatch ? `
          <div style="
            padding:12px 14px;
            background:#FBEEDA;border-radius:14px;
            display:flex;align-items:center;gap:10px;
          ">
            <span style="color:#E8912B;font-size:20px;">🏆</span>
            <div style="flex:1;">
              <div style="font-size:10.5px;font-weight:700;color:rgba(0,0,0,0.45);letter-spacing:0.3px;">ЛУЧШИЙ УЛОВ</div>
              <div style="font-size:13.5px;font-weight:700;color:#2D2D2D;">${client.bestCatch.species} · ${client.bestCatch.weight}</div>
            </div>
            <div>
              <div style="font-size:10.5px;font-weight:700;color:rgba(0,0,0,0.45);letter-spacing:0.3px;">СЕКТОР №${client.bestCatch.sector}</div>
              <div style="font-size:13.5px;font-weight:700;color:#2D2D2D;">${client.bestCatch.date}</div>
            </div>
          </div>
        ` : ''}
      </div>
    </div>
  `;

  document.body.appendChild(overlay);
  overlay.querySelector('#client-card-close')?.addEventListener('click', () => overlay.remove());
  overlay.addEventListener('click', (e) => { if (e.target === overlay) overlay.remove(); });
}
