// === FilterDropdown (точь-в-точь Flutter filter_dropdown.dart) ===
// Overlay-based dropdown для фильтров.
// height: 44, borderRadius: 12, fill: #F3EEE4

export function createFilterDropdown(containerEl, options) {
  const { value, label, items, onChanged, active = false } = options;
  const BORDER_RADIUS = 12;
  const ITEM_HEIGHT = 42;

  let currentValue = value;
  let open = false;
  let overlayEl = null;

  function render() {
    const displayLabel = getDisplayLabel();
    const isActive = currentValue != null;

    containerEl.innerHTML = '';
    containerEl.style.cssText = `
      position:relative;
      height:44px;
      background:#F3EEE4;
      border-radius:${open ? `${BORDER_RADIUS}px ${BORDER_RADIUS}px 0 0` : `${BORDER_RADIUS}px`};
      padding:0 12px;
      display:flex;
      align-items:center;
      cursor:pointer;
      user-select:none;
      flex:1;
      min-width:0;
    `;

    const textEl = document.createElement('span');
    textEl.style.cssText = `
      flex:1;
      overflow:hidden;
      text-overflow:ellipsis;
      white-space:nowrap;
      font-size:14px;
      font-weight:${isActive ? '700' : '400'};
      color:${isActive ? '#14130F' : '#9C9484'};
    `;
    textEl.textContent = displayLabel;

    const arrowWrap = document.createElement('span');
    arrowWrap.style.cssText = 'position:relative;display:flex;align-items:center;flex-shrink:0;';
    const arrow = document.createElement('span');
    arrow.style.cssText = `font-size:20px;color:#9C9484;transition:transform 0.15s;transform:rotate(${open ? 180 : 0}deg);`;
    arrow.textContent = '▾';
    arrowWrap.appendChild(arrow);

    // Оранжевая точка-индикатор (как Flutter)
    if (active) {
      const dot = document.createElement('span');
      dot.style.cssText = 'position:absolute;top:0;right:0;width:7px;height:7px;border-radius:50%;background:#E8912B;';
      arrowWrap.appendChild(dot);
    }

    containerEl.appendChild(textEl);
    containerEl.appendChild(arrowWrap);

    containerEl.onclick = (e) => {
      e.stopPropagation();
      open ? close() : show();
    };
  }

  function getDisplayLabel() {
    if (currentValue != null) {
      for (const item of items) {
        if (item.value === currentValue && !item.isReset) return item.label;
      }
    }
    return label;
  }

  function show() {
    open = true;
    render();

    const rect = containerEl.getBoundingClientRect();
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
    const scrollLeft = window.pageXOffset || document.documentElement.scrollLeft;

    overlayEl = document.createElement('div');
    overlayEl.style.cssText = `
      position:fixed;
      top:${rect.bottom}px;
      left:${rect.left}px;
      width:${rect.width}px;
      max-height:${window.innerHeight - rect.bottom - 80}px;
      background:#F3EEE4;
      border-radius:0 0 ${BORDER_RADIUS}px ${BORDER_RADIUS}px;
      box-shadow:0 6px 10px rgba(0,0,0,0.13);
      overflow-y:auto;
      z-index:1000;
      padding:0;
    `;

    items.forEach(item => {
      const selected = item.value === currentValue && item.value != null;
      const itemEl = document.createElement('div');
      itemEl.style.cssText = `
        width:100%;
        height:${ITEM_HEIGHT}px;
        padding:0 12px;
        display:flex;
        align-items:center;
        cursor:${item.enabled === false ? 'default' : 'pointer'};
        background:${selected ? '#EFD9AC' : 'transparent'};
        font-size:14px;
        font-weight:${item.isReset ? '400' : selected ? '700' : '400'};
        color:${item.enabled === false ? '#EFE8D8' : item.isReset ? '#9C9484' : '#14130F'};
      `;
      itemEl.textContent = item.label;
      if (item.enabled !== false) {
        itemEl.onclick = (e) => {
          e.stopPropagation();
          onChanged(item.value);
          currentValue = item.value;
          close();
        };
        itemEl.onmouseenter = () => { if (!selected) itemEl.style.background = '#EFD9AC'; };
        itemEl.onmouseleave = () => { if (!selected) itemEl.style.background = 'transparent'; };
      }
      overlayEl.appendChild(itemEl);
    });

    document.body.appendChild(overlayEl);
    setTimeout(() => document.addEventListener('click', close), 0);

    // Перепозиционирование при скролле
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
