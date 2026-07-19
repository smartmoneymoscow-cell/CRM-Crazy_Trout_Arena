// === ESC/POS Encoder ===
const ESC = 0x1B;
const GS = 0x1D;
const LF = 0x0A;

class EscPosEncoder {
  constructor() { this.parts = []; this.encoder = new TextEncoder(); }
  initialize() { this.parts.push(new Uint8Array([ESC, 0x40])); return this; }
  text(str) { this.parts.push(this.encoder.encode(str)); return this; }
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
