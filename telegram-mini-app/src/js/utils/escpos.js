// === ESC/POS Encoder (CP866 — как Flutter escpos_builder.dart) ===
const ESC = 0x1B;
const GS = 0x1D;
const LF = 0x0A;

// CP866 кодировка кириллицы (DOS Cyrillic) — точная копия из Flutter
const CP866_MAP = {
  'А': 0x80, 'Б': 0x81, 'В': 0x82, 'Г': 0x83, 'Д': 0x84, 'Е': 0x85, 'Ж': 0x86, 'З': 0x87,
  'И': 0x88, 'Й': 0x89, 'К': 0x8A, 'Л': 0x8B, 'М': 0x8C, 'Н': 0x8D, 'О': 0x8E, 'П': 0x8F,
  'Р': 0x90, 'С': 0x91, 'Т': 0x92, 'У': 0x93, 'Ф': 0x94, 'Х': 0x95, 'Ц': 0x96, 'Ч': 0x97,
  'Ш': 0x98, 'Щ': 0x99, 'Ъ': 0x9A, 'Ы': 0x9B, 'Ь': 0x9C, 'Э': 0x9D, 'Ю': 0x9E, 'Я': 0x9F,
  'а': 0xA0, 'б': 0xA1, 'в': 0xA2, 'г': 0xA3, 'д': 0xA4, 'е': 0xA5, 'ж': 0xA6, 'з': 0xA7,
  'и': 0xA8, 'й': 0xA9, 'к': 0xAA, 'л': 0xAB, 'м': 0xAC, 'н': 0xAD, 'о': 0xAE, 'п': 0xAF,
  'р': 0xE0, 'с': 0xE1, 'т': 0xE2, 'у': 0xE3, 'ф': 0xE4, 'х': 0xE5, 'ц': 0xE6, 'ч': 0xE7,
  'ш': 0xE8, 'щ': 0xE9, 'ъ': 0xEA, 'ы': 0xEB, 'ь': 0xEC, 'э': 0xED, 'ю': 0xEE, 'я': 0xEF,
  'Ё': 0xF0, 'ё': 0xF1, '№': 0xFC,
};

function encodeCP866(str) {
  const bytes = [];
  for (const ch of str) {
    const code = ch.codePointAt(0);
    if (ch in CP866_MAP) {
      bytes.push(CP866_MAP[ch]);
    } else if (code < 128) {
      bytes.push(code);
    } else {
      // Неизвестный символ — заменяем на '?'
      bytes.push(0x3F);
    }
  }
  return new Uint8Array(bytes);
}

class EscPosEncoder {
  constructor() { this.parts = []; }
  initialize() { this.parts.push(new Uint8Array([ESC, 0x40])); return this; }
  text(str) { this.parts.push(encodeCP866(str)); return this; }
  line(str) { this.text(str + '\n'); return this; }
  newline(count = 1) { for (let i = 0; i < count; i++) this.parts.push(new Uint8Array([LF])); return this; }
  bold(on = true) { this.parts.push(new Uint8Array([ESC, 0x45, on ? 1 : 0])); return this; }
  doubleSize(on = true) { this.parts.push(new Uint8Array([ESC, 0x21, on ? 0x30 : 0x00])); return this; }
  resetSize() { this.parts.push(new Uint8Array([GS, 0x21, 0x00])); return this; }
  align(mode = 'left') { this.parts.push(new Uint8Array([ESC, 0x61, { left: 0, center: 1, right: 2 }[mode] || 0])); return this; }
  separator(char = '─', width = 32) { this.line(char.repeat(width)); return this; }
  cut(mode = 'full') { this.parts.push(new Uint8Array([GS, 0x56, mode === 'partial' ? 1 : 0])); return this; }
  feed(lines = 3) { for (let i = 0; i < lines; i++) this.parts.push(new Uint8Array([LF])); return this; }
  encode() {
    const totalLength = this.parts.reduce((sum, arr) => sum + arr.length, 0);
    const result = new Uint8Array(totalLength);
    let offset = 0;
    for (const part of this.parts) { result.set(part, offset); offset += part.length; }
    return result;
  }
  buildReceipt(receipt, config = {}) {
    const { sellerName = 'ИП Crazy Trout Arena', inn = '7701234567', taxSystem = 'УСН доходы', fn = '8710000100412345', address = 'г. Москва, ул. Прудовая, д. 1', website = 'nalog.gov.ru' } = config;
    this.initialize();
    this.align('center').doubleSize().bold();
    this.line('CRAZY TROUT ARENA');
    this.resetSize().bold(false);
    this.line(address);
    this.line(`ИНН: ${inn}`);
    this.separator('─');
    this.newline();
    this.align('left');
    this.line(`Чек №${receipt.id}`);
    this.line(`Дата: ${receipt.date}`);
    this.line(`Тариф: ${receipt.tariffLabel} — ${receipt.tariffPrice}₽`);
    this.separator('─');
    if (receipt.catches?.length) {
      this.bold().line('УЛОВ:').bold(false);
      for (const c of receipt.catches) {
        const weight = c.kg > 0 ? `${c.kg}кг${c.grams > 0 ? c.grams + 'г' : ''}` : `${c.grams}г`;
        this.line(`  ${c.breedLabel} ${weight}`);
        this.line(`  × ${c.pricePerKg}₽/кг = ${c.sum}₽`);
      }
      this.separator('─');
    }
    this.align('center').doubleSize().bold();
    this.line(`ИТОГО: ${receipt.total}₽`);
    this.resetSize().bold(false);
    this.newline();
    const paymentLabels = { cash: 'Наличные', card: 'Карта', account: 'Счёт заведения' };
    this.align('left');
    this.line(`Оплата: ${paymentLabels[receipt.paymentMethod] || receipt.paymentMethod}`);
    if (receipt.fiscal) {
      this.separator('─');
      this.line(`СНО: ${taxSystem}`);
      this.line(`ФН: ${fn}`);
      this.line(`ФД: ${receipt.id}`);
      this.line(`Сайт ФНС: ${website}`);
    }
    this.newline(2);
    this.cut('full');
    return this.encode();
  }
  static encode(receipt, config) { return new EscPosEncoder().buildReceipt(receipt, config); }
}
export { EscPosEncoder };
