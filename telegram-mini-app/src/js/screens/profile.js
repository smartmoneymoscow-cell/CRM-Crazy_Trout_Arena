// === Screen: Профиль (как Flutter StubScreen) ===
import { tg } from '../core/telegram.js';

export function renderProfile() {
  const el = document.createElement('div');
  el.className = 'screen screen-profile';
  el.innerHTML = `
    <div style="display:flex;flex-direction:column;align-items:center;justify-content:center;padding:32px;text-align:center;min-height:60vh;">
      <div style="font-size:40px;color:#BBAF95;margin-bottom:12px;"><svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#BBAF95" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg></div>
      <div style="font-size:22px;font-weight:800;color:var(--kInk);margin-bottom:8px;">Профиль</div>
      <div style="font-size:13px;color:#9C9484;line-height:1.5;max-width:280px;">
        Профиль администратора — раздел в разработке.
      </div>
    </div>
  `;
  return el;
}
