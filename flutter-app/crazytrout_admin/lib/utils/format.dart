/// Форматирование чисел в денежный формат: 1 500 ₽
String money(num n) {
  final rounded = n.round();
  final s = rounded.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]} ',
      );
  return '$s ₽';
}
