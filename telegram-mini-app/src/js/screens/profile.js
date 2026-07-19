// === Screen: Профиль (как Flutter StubScreen — заглушка) ===
import { tg } from '../core/telegram.js';

export function renderProfile() {
  const el = document.createElement('div');
  el.className = 'screen screen-profile';
  el.innerHTML = `
    <div style="display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:60vh;text-align:center;">
      <div style="font-size:40px;color:#BBAF95;margin-bottom:16px;">
        <svg width="40" height="40" viewBox="0 0 24 24" fill="#BBAF95"><path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4zm0-6c1.1 0 2 .9 2 2s-.9 2-2 2-2-.9-2-2 .9-2 2-2z"/></svg>
      </div>
      <div style="font-size:18px;font-weight:700;color:var(--kInk);margin-bottom:8px;">Профиль</div>
      <div style="font-size:13px;color:var(--kMuted2);max-width:240px;">Профиль администратора — раздел в разработке.</div>
    </div>
  `;
  return el;
}
