import '../models/client.dart';
import '../models/tariff.dart';

/// Тарифы. Значения синхронизированы с веб-версией:
/// Стандарт 750 ₽, Гостевой 500 ₽, Пенсионер 0 ₽.
const List<Tariff> kTariffs = [
  Tariff(id: 'standard', label: 'Стандарт', price: 750),
  Tariff(id: 'guest', label: 'Гостевой', price: 500),
  Tariff(id: 'pensioner', label: 'Пенсионер', price: 0),
];

/// Породы рыбы, доступные для добавления в улов (без варианта «Другое» —
/// цена всегда фиксированная и берётся автоматически).
const List<String> kSpecies = ['Осётр', 'Карп', 'Амур', 'Линь', 'Форель'];

/// Фиксированная цена за кг для каждой породы.
const Map<String, double> kSpeciesPrice = {
  'Осётр': 1890,
  'Карп': 590,
  'Амур': 750,
  'Линь': 690,
  'Форель': 1200,
};

/// Изображение рыбы для каждой породы (используется в выпадающем списке
/// и в закрытом поле выбора породы). Картинки вырезаны с фона и приведены
/// к единому прямоугольному холсту, подобранному под самую вытянутую рыбу
/// (осётр), поэтому все виды используют кадр по максимуму.
const Map<String, String> kSpeciesImage = {
  'Осётр': 'assets/fish/sturgeon.png',
  'Карп': 'assets/fish/carp.png',
  'Амур': 'assets/fish/grass_carp.png',
  'Линь': 'assets/fish/tench.png',
  'Форель': 'assets/fish/trout.png',
};

/// Высота миниатюры рыбы в выпадающем списке — по умолчанию одинаковая
/// для всех, но осётр и амур крупнее остальных, чтобы подчеркнуть их
/// как самых заметных/крупных обитателей пруда. Ширина всегда считается
/// автоматически по пропорциям картинки (см. AppDropdownField).
const double kSpeciesImageHeightDefault = 32;
const Map<String, double> kSpeciesImageHeight = {
  'Осётр': 44,
  'Амур': 40,
  'Форель': 36,
  'Карп': 36,
};

/// Демо-клиенты для поиска (в реальном приложении — из backend).
/// У первых 4-х есть фото-аватары, у остальных — инициалы.
const List<Client> kDemoClients = [
  Client(id: 1, name: 'Иван Иванов', phone: '+7 925 123-45-67', tariffLabel: 'Стандарт',
         avatarAsset: 'assets/avatars/avatar_1.jpeg'),
  Client(id: 2, name: 'Алексей Кошкин', phone: '+7 916 555-22-11', tariffLabel: 'Стандарт',
         avatarAsset: 'assets/avatars/avatar_2.jpeg'),
  Client(id: 3, name: 'Сергей Петров', phone: '+7 903 777-44-33', tariffLabel: 'Стандарт',
         avatarAsset: 'assets/avatars/avatar_3.jpeg'),
  Client(id: 5, name: 'Дмитрий Лагута', phone: '+7 985 111-22-33', tariffLabel: 'Стандарт',
         avatarAsset: 'assets/avatars/avatar_5.jpeg'),
  Client(id: 6, name: 'Михаил Орлов', phone: '+7 962 888-99-00', tariffLabel: 'Пенсионер',
         avatarAsset: 'assets/avatars/avatar_6.jpeg'),
  Client(id: 7, name: 'Олег Сидоров', phone: '+7 905 222-77-66', tariffLabel: 'Стандарт',
         avatarAsset: 'assets/avatars/avatar_7.jpeg'),
  Client(id: 8, name: 'Виктор Щукин', phone: '+7 910 444-55-66', tariffLabel: 'Стандарт',
         avatarAsset: 'assets/avatars/avatar_8.jpeg'),
  // Мок-клиент для тестирования QR-сканирования
  Client(id: 100, name: 'Тест Клиент', phone: '+7 999 000-00-00', tariffLabel: 'Стандарт'),
];
