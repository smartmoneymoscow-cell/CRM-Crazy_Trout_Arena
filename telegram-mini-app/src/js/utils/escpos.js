// === ESC/POS Encoder ===
// Генерация ESC/POS байт-массива для термопринтера
// Поддержка кириллицы UTF-8, 54-ФЗ реквизиты

const ESC = 0x1B;
const GS  = 0x1D;
const LF  = 0x0A;

class EscPosEncoder {
  constructor() {
    this.parts = [];
    this.encoder = new TextEncoder();
  }

  // --- Инициализация ---
  
  initialize() {
    this.parts.push(new Uint8Array([ESC, 0x40])); // ESC @
    return this;
  }

  // --- Текст ---
  
  text(str) {
    this.parts.push(this.encoder.encode(str));
    return this;
  }

  line(str) {
    this.text(str + '\n');
    return this;
  }

  newline(count = 1) {
    for (let i = 0; i < count; i++) {
      this.parts.push(new Uint8Array([LF]));
    }
    return this;
  }

  // --- Форматирование ---
  
  bold(on = true) {
    this.parts.push(new Uint8Array([ESC, 0x45, on ? 0x01 : 0x00]));
    return this;
  }

  doubleWidth(on = true) {
    this.parts.push(new Uint8Array([ESC, 0x21, on ? 0x20 : 0x00]));
    return this;
  }

  doubleHeight(on = true) {
    this.parts.push(new Uint8Array([ESC, 0x21, on ? 0x10 : 0x00]));
    return this;
  }

  doubleSize(on = true) {
    this.parts.push(new Uint8Array([ESC, 0x21, on ? 0x30 : 0x00]));
    return this;
  }

  align(mode = 'left') {
    const modes = { left: 0, center: 1, right: 2 };
    this.parts.push(new Uint8Array([ESC, 0x61, modes[mode] || 0]));
    return this;
  }

  size(width = 1, height = 1) {
    // width/height: 1-8
    const w = Math.min(8, Math.max(1, width)) - 1;
    const h = Math.min(8, Math.max(1, height)) - 1;
    const n = (w << 4) | h;
    this.parts.push(new Uint8Array([GS, 0x21, n]));
    return this;
  }

  resetSize() {
    this.parts.push(new Uint8Array([GS, 0x21, 0x00]));
    return this;
  }

  // --- Разделители ---
  
  separator(char = '─', width = 32) {
    this.line(char.repeat(width));
    return this;
  }

  dashedLine(width = 32) {
    this.line('- '.repeat(width / 2).trim());
    return this;
  }

  // --- QR-код ---
  
  qr(data, size = 6) {
    const storeLen = data.length + 3;
    const storeLenH = (storeLen >> 8) & 0xFF;
    const storeLenL = storeLen & 0xFF;

    // Модель QR
    this.parts.push(new Uint8Array([GS, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00]));
    // Размер модуля
    this.parts.push(new Uint8Array([GS, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, size]));
    // Коррекция ошибок
    this.parts.push(new Uint8Array([GS, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, 0x30]));
    // Сохранение данных
    this.parts.push(new Uint8Array([GS, 0x28, 0x6B, storeLenL, storeLenH, 0x31, 0x50, 0x30]));
    this.parts.push(this.encoder.encode(data));
    // Печать QR
    this.parts.push(new Uint8Array([GS, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]));

    return this;
  }

  // --- Отрез бумаги ---
  
  cut(mode = 'full') {
    // mode: 'full' | 'partial'
    this.parts.push(new Uint8Array([GS, 0x56, mode === 'partial' ? 0x01 : 0x00]));
    return this;
  }

  // --- Подача бумаги ---
  
  feed(lines = 3) {
    for (let i = 0; i < lines; i++) {
      this.parts.push(new Uint8Array([LF]));
    }
    return this;
  }

  // --- Компилирование ---
  
  encode() {
    const totalLength = this.parts.reduce((sum, arr) => sum + arr.length, 0);
    const result = new Uint8Array(totalLength);
    let offset = 0;
    for (const part of this.parts) {
      result.set(part, offset);
      offset += part.length;
    }
    return result;
  }

  // --- Сборка чека (54-ФЗ) ---
  
  buildReceipt(receipt, config = {}) {
    const {
      sellerName = 'ИП Crazy Trout Arena',
      inn = '7701234567',
      taxSystem = 'УСН доходы',
      fn = '8710000100412345',
      fd = '12345',
      fpd = '6789012345',
      address = 'г. Москва, ул. Прудовая, д. 1',
      website = 'nalog.gov.ru',
    } = config;

    this.initialize();

    // Заголовок
    this.align('center').doubleSize().bold();
    this.line('CRAZY TROUT ARENA');
    this.resetSize().bold(false);
    this.line(address);
    this.line(`ИНН: ${inn}`);
    this.separator('─');
    this.newline();

    // Данные чека
    this.align('left');
    this.line(`Чек №${receipt.id}`);
    this.line(`Дата: ${receipt.date}`);
    this.line(`Тариф: ${receipt.tariffLabel} — ${receipt.tariffPrice}₽`);
    this.separator('─');

    // Улов
    if (receipt.catches?.length) {
      this.bold().line('УЛОВ:').bold(false);
      for (const c of receipt.catches) {
        const weight = c.kg > 0 ? `${c.kg}кг${c.grams > 0 ? c.grams + 'г' : ''}` : `${c.grams}г`;
        this.line(`  ${c.breedLabel} ${weight}`);
        this.line(`  × ${c.pricePerKg}₽/кг = ${c.sum}₽`);
      }
      this.separator('─');
    }

    // Итого
    this.align('center').doubleSize().bold();
    this.line(`ИТОГО: ${receipt.total}₽`);
    this.resetSize().bold(false);
    this.newline();

    // Способ оплаты
    const paymentLabels = { cash: 'Наличные', card: 'Карта', account: 'Счёт заведения' };
    this.align('left');
    this.line(`Оплата: ${paymentLabels[receipt.paymentMethod] || receipt.paymentMethod}`);
    this.separator('─');

    // 54-ФЗ реквизиты
    if (receipt.fiscal) {
      this.newline();
      this.size(1, 1);
      this.line(`СНО: ${taxSystem}`);
      this.line(`ФН: ${fn}`);
      this.line(`ФД: ${fd}`);
      this.line(`ФПД: ${fpd}`);
      this.line(`Сайт ФНС: ${website}`);
      this.newline();
    }

    // QR-код с ссылкой на чек
    this.align('center');
    this.qr(`${website}/receipt/${receipt.id}`, 6);
    this.newline(2);

    // Отрез
    this.cut('full');

    return this.encode();
  }

  // --- Статический метод ---
  
  static encode(receipt, config) {
    return new EscPosEncoder()
      .buildReceipt(receipt, config);
  }
}

export { EscPosEncoder };
