// === Calendar Picker (как Flutter _showRangeCalendarPicker) ===
// Диапазон дат с календарём в модальном окне.

export function showCalendarPicker(currentRange) {
  return new Promise((resolve) => {
    let startDate = currentRange?.start ? new Date(currentRange.start) : null;
    let endDate = currentRange?.end ? new Date(currentRange.end) : null;
    let selectingStart = true;
    let viewDate = new Date();

    const overlay = document.createElement('div');
    overlay.className = 'modal-overlay';

    function render() {
      overlay.innerHTML = '';
      overlay.innerHTML = `
        <div class="sheet" style="max-width:340px;padding:20px;">
          <div style="text-align:center;font-size:18px;font-weight:700;color:#14130F;margin-bottom:16px;">Выберите период</div>

          <!-- Навигация месяца -->
          <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:12px;">
            <button id="cal-prev" style="background:none;border:none;font-size:20px;cursor:pointer;padding:4px 8px;color:#9C9484;">‹</button>
            <span style="font-size:15px;font-weight:600;color:#14130F;">${MONTHS[viewDate.getMonth()]} ${viewDate.getFullYear()}</span>
            <button id="cal-next" style="background:none;border:none;font-size:20px;cursor:pointer;padding:4px 8px;color:#9C9484;">›</button>
          </div>

          <!-- Дни недели -->
          <div style="display:grid;grid-template-columns:repeat(7,1fr);gap:2px;margin-bottom:4px;">
            ${['Пн','Вт','Ср','Чт','Пт','Сб','Вс'].map(d => `<div style="text-align:center;font-size:11px;color:#9C9484;padding:4px;">${d}</div>`).join('')}
          </div>

          <!-- Календарь -->
          <div id="cal-grid" style="display:grid;grid-template-columns:repeat(7,1fr);gap:2px;"></div>

          <!-- Выбранный диапазон -->
          <div style="margin-top:12px;text-align:center;font-size:13px;color:#8C8576;">
            ${startDate ? formatDate(startDate) : '...'} — ${endDate ? formatDate(endDate) : '...'}
          </div>

          <!-- Кнопки -->
          <div style="display:flex;gap:12px;margin-top:16px;">
            <button id="cal-reset" style="flex:1;height:44px;border-radius:12px;background:transparent;border:1px solid #DDD3BC;color:#8C8576;font-weight:600;cursor:pointer;">Сбросить</button>
            <button id="cal-apply" style="flex:1;height:44px;border-radius:12px;background:#E8912B;border:none;color:#fff;font-weight:600;cursor:pointer;">Применить</button>
          </div>
        </div>
      `;

      renderGrid();

      overlay.querySelector('#cal-prev')?.addEventListener('click', () => {
        viewDate.setMonth(viewDate.getMonth() - 1);
        render();
      });
      overlay.querySelector('#cal-next')?.addEventListener('click', () => {
        viewDate.setMonth(viewDate.getMonth() + 1);
        render();
      });
      overlay.querySelector('#cal-reset')?.addEventListener('click', () => {
        overlay.remove();
        resolve({ start: new Date(2000, 0, 1), end: new Date(2000, 0, 1) }); // маркер сброса
      });
      overlay.querySelector('#cal-apply')?.addEventListener('click', () => {
        overlay.remove();
        if (startDate && endDate) {
          resolve({ start: startDate, end: endDate });
        } else {
          resolve(null);
        }
      });
      overlay.addEventListener('click', (e) => { if (e.target === overlay) { overlay.remove(); resolve(null); } });
    }

    function renderGrid() {
      const grid = overlay.querySelector('#cal-grid');
      if (!grid) return;

      const year = viewDate.getFullYear();
      const month = viewDate.getMonth();
      const firstDay = new Date(year, month, 1);
      const lastDay = new Date(year, month + 1, 0);
      const startDow = (firstDay.getDay() + 6) % 7; // Пн=0

      const today = new Date();
      today.setHours(0, 0, 0, 0);

      let html = '';
      // Пустые ячейки
      for (let i = 0; i < startDow; i++) html += '<div></div>';

      for (let d = 1; d <= lastDay.getDate(); d++) {
        const date = new Date(year, month, d);
        date.setHours(0, 0, 0, 0);
        const isToday = date.getTime() === today.getTime();
        const isStart = startDate && date.getTime() === startDate.getTime();
        const isEnd = endDate && date.getTime() === endDate.getTime();
        const inRange = startDate && endDate && date > startDate && date < endDate;

        let bg = 'transparent';
        let color = '#14130F';
        let borderRadius = '50%';

        if (isStart || isEnd) {
          bg = '#E8912B';
          color = '#fff';
        } else if (inRange) {
          bg = '#EFD9AC';
          borderRadius = '0';
        }

        if (isToday && !isStart && !isEnd) {
          color = '#E8912B';
          fontWeight = '700';
        }

        html += `<div data-date="${date.toISOString()}" style="
          text-align:center;
          padding:8px 4px;
          font-size:13px;
          cursor:pointer;
          background:${bg};
          color:${color};
          border-radius:${borderRadius};
          font-weight:${isToday ? '700' : '400'};
        ">${d}</div>`;
      }

      grid.innerHTML = html;

      grid.querySelectorAll('[data-date]').forEach(cell => {
        cell.addEventListener('click', () => {
          const clicked = new Date(cell.dataset.date);
          clicked.setHours(0, 0, 0, 0);
          if (selectingStart || clicked < startDate) {
            startDate = clicked;
            endDate = null;
            selectingStart = false;
          } else {
            endDate = clicked;
            selectingStart = true;
          }
          render();
        });
      });
    }

    render();
    document.body.appendChild(overlay);
  });
}

const MONTHS = ['Январь','Февраль','Март','Апрель','Май','Июнь','Июль','Август','Сентябрь','Октябрь','Ноябрь','Декабрь'];

function formatDate(d) {
  const two = n => String(n).padStart(2, '0');
  return `${two(d.getDate())}.${two(d.getMonth() + 1)}.${d.getFullYear()}`;
}
