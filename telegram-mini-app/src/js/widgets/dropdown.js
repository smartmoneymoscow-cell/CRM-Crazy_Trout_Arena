// === OverlayEntry Dropdown (точь-в-точь Flutter AppDropdownField) ===
// CompositedTransformFollower-паттерн: меню точно ширины поля, без зазора,
// нижние углы поля становятся прямыми при открытии.

export function createDropdown(containerEl, items, currentValue, onChange, options = {}) {
  const { fillColor = '#F3EEE4', borderRadius = 10, contentPadding = '12px 10px', maxMenuHeight = 320 } = options;

  let open = false;
  let overlayEl = null;

  function render() {
    const selected = items.find(i => i.value === currentValue) || items[0];
    containerEl.innerHTML = '';
    containerEl.style.cssText = `
      position: relative;
      background: ${fillColor};
      border-radius: ${open ? `${borderRadius}px ${borderRadius}px 0 0` : `${borderRadius}px`};
      padding: ${contentPadding};
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: space-between;
      min-height: 44px;
      transition: border-radius 0.1s;
      user-select: none;
    `;

    const labelEl = document.createElement('span');
    labelEl.style.cssText = 'flex:1;font-size:14px;color:#14130F;';
    if (typeof selected.render === 'function') {
      labelEl.innerHTML = '';
      labelEl.appendChild(selected.render());
    } else {
      labelEl.textContent = selected.label || selected.value;
    }

    const arrowEl = document.createElement('span');
    arrowEl.style.cssText = `color:#9C9484;font-size:18px;flex-shrink:0;transition:transform 0.15s;transform:rotate(${open ? 180 : 0}deg);`;
    arrowEl.textContent = '▾';

    containerEl.appendChild(labelEl);
    containerEl.appendChild(arrowEl);

    containerEl.onclick = (e) => {
      e.stopPropagation();
      open ? close() : show();
    };
  }

  function show() {
    open = true;
    render();

    const rect = containerEl.getBoundingClientRect();
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
    const scrollLeft = window.pageXOffset || document.documentElement.scrollLeft;

    overlayEl = document.createElement('div');
    overlayEl.style.cssText = `
      position: fixed;
      top: ${rect.bottom}px;
      left: ${rect.left}px;
      width: ${rect.width}px;
      background: ${fillColor};
      border-radius: 0 0 ${borderRadius}px ${borderRadius}px;
      box-shadow: 0 6px 10px rgba(0,0,0,0.13);
      max-height: ${maxMenuHeight}px;
      overflow-y: auto;
      z-index: 1000;
      padding: 0;
    `;

    items.forEach(item => {
      const selected = item.value === currentValue;
      const itemEl = document.createElement('div');
      itemEl.style.cssText = `
        padding: ${contentPadding};
        cursor: pointer;
        font-size: 14px;
        transition: background 0.1s;
        display: flex;
        align-items: center;
        gap: 8px;
        background: ${selected ? '#EFD9AC' : 'transparent'};
        font-weight: ${selected ? '700' : '400'};
        color: #14130F;
      `;
      if (typeof item.render === 'function') {
        itemEl.appendChild(item.render());
      } else {
        itemEl.textContent = item.label || item.value;
      }
      itemEl.onmouseenter = () => { itemEl.style.background = '#EFD9AC'; };
      itemEl.onmouseleave = () => { if (!selected) itemEl.style.background = 'transparent'; };
      itemEl.onclick = (e) => {
        e.stopPropagation();
        currentValue = item.value;
        onChange(currentValue);
        close();
      };
      overlayEl.appendChild(itemEl);
    });

    document.body.appendChild(overlayEl);

    // Клик вне меню — закрыть
    setTimeout(() => document.addEventListener('click', close), 0);

    // Перепозиционирование при скролле (как Flutter CompositedTransformFollower)
    const reposition = () => {
      if (!overlayEl || !open) return;
      const newRect = containerEl.getBoundingClientRect();
      overlayEl.style.top = `${newRect.bottom}px`;
      overlayEl.style.left = `${newRect.left}px`;
      overlayEl.style.width = `${newRect.width}px`;
    };
    window.addEventListener('scroll', reposition, true);
    window.addEventListener('resize', reposition);
    const origClose = close;
    close = function() {
      window.removeEventListener('scroll', reposition, true);
      window.removeEventListener('resize', reposition);
      origClose();
    };
  }

  function close() {
    open = false;
    render();
    if (overlayEl) { overlayEl.remove(); overlayEl = null; }
    document.removeEventListener('click', close);
  }

  render();

  return {
    setValue(v) { currentValue = v; render(); },
    getValue() { return currentValue; },
    close,
  };
}
