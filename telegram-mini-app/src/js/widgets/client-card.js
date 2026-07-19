// === Client Card Modal (точь-в-точь Flutter _ClientCard) ===
// Градиентный хедер, медаль, progress bar лояльности, статистика.

import { store } from '../core/store.js';

const LEVEL_COLORS = {
  premium:  { color: '#B8862E', top: '#FFE18A', mid: '#E0A62E', bottom: '#AD7A16', letter: '#4A3300' },
  standard: { color: '#8B94A0', top: '#F2F5F8', mid: '#C9D1D9', bottom: '#98A2AD', letter: '#2E3438' },
  basic:    { color: '#8C5C34', top: '#E3B98B', mid: '#C08A54', bottom: '#8C5C34', letter: '#FFFFFF' },
};

export function showClientCard(clientId) {
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
            <div style="color:#fff;font-size:17px;font-weight:700;">${client.name}</div>
            <div style="margin-top:4px;">
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
          <div style="height:4px;border-radius:2px;background:rgba(255,255,255,0.15);margin-top:4px;overflow:hidden;">
            <div style="height:100%;width:${pct}%;background:linear-gradient(90deg,${l.top},${l.mid});border-radius:2px;"></div>
          </div>
        </div>
      </div>

      <!-- Статистика -->
      <div style="padding:18px 20px;">
        <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:12px;text-align:center;margin-bottom:16px;">
          <div>
            <div style="font-size:18px;font-weight:700;color:#E8912B;">${client.visits}</div>
            <div style="font-size:10px;color:#9C9484;margin-top:2px;">Посещений</div>
          </div>
          <div>
            <div style="font-size:18px;font-weight:700;color:#E8912B;">${store.formatMoney(ltv)} ₽</div>
            <div style="font-size:10px;color:#9C9484;margin-top:2px;">LTV</div>
          </div>
          <div>
            <div style="font-size:18px;font-weight:700;color:#E8912B;">${avgCatch.kg} кг</div>
            <div style="font-size:10px;color:#9C9484;margin-top:2px;">Ср. улов</div>
          </div>
        </div>

        <!-- Телефон -->
        <div style="display:flex;justify-content:space-between;padding:8px 0;border-top:0.5px solid #E7E0D1;">
          <span style="color:#8C8576;font-size:13px;">Телефон</span>
          <span style="font-size:13px;font-weight:600;">${client.phone}</span>
        </div>
        <!-- Тариф -->
        <div style="display:flex;justify-content:space-between;padding:8px 0;border-top:0.5px solid #E7E0D1;">
          <span style="color:#8C8576;font-size:13px;">Тариф</span>
          <span style="font-size:13px;font-weight:600;">${client.tariff === 'standard' ? 'Стандарт' : client.tariff === 'pensioner' ? 'Пенсионер' : 'Гостевой'}</span>
        </div>
        <!-- Баллы -->
        <div style="display:flex;justify-content:space-between;padding:8px 0;border-top:0.5px solid #E7E0D1;">
          <span style="color:#8C8576;font-size:13px;">Баллы</span>
          <span style="font-size:13px;font-weight:600;">${client.points} / ${client.pointsNext}</span>
        </div>

        <button class="btn btn-ghost btn-full" style="margin-top:16px;color:#9C9484;">Закрыть</button>
      </div>
    </div>
  `;

  document.body.appendChild(overlay);
  overlay.querySelector('.btn-ghost')?.addEventListener('click', () => overlay.remove());
  overlay.addEventListener('click', (e) => { if (e.target === overlay) overlay.remove(); });
}
