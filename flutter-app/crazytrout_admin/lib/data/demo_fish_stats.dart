// ============================================================================
// demo_fish_stats.dart — Демо-данные для экрана «Статистика улова рыбы».
//
// В production заменяется на выборку из backend.
// ============================================================================

class FishSpeciesStats {
  final String species;
  final String imageAsset;
  final int count;       // количество пойманных штук
  final double weightKg; // общий вес в кг
  final double pricePerKg;
  final int remaining;   // остаток в пруду (шт.)

  const FishSpeciesStats({
    required this.species,
    required this.imageAsset,
    required this.count,
    required this.weightKg,
    required this.pricePerKg,
    required this.remaining,
  });

  double get revenue => weightKg * pricePerKg;
  double get avgWeight => count > 0 ? weightKg / count : 0;
}

const List<FishSpeciesStats> kDemoFishStats = [
  FishSpeciesStats(
    species: 'Осётр',
    imageAsset: 'assets/fish/sturgeon.png',
    count: 87,
    weightKg: 312.5,
    pricePerKg: 1890,
    remaining: 38,
  ),
  FishSpeciesStats(
    species: 'Карп',
    imageAsset: 'assets/fish/carp.png',
    count: 145,
    weightKg: 289.3,
    pricePerKg: 590,
    remaining: 120,
  ),
  FishSpeciesStats(
    species: 'Амур',
    imageAsset: 'assets/fish/grass_carp.png',
    count: 63,
    weightKg: 178.6,
    pricePerKg: 750,
    remaining: 45,
  ),
  FishSpeciesStats(
    species: 'Линь',
    imageAsset: 'assets/fish/tench.png',
    count: 41,
    weightKg: 67.2,
    pricePerKg: 690,
    remaining: 22,
  ),
  FishSpeciesStats(
    species: 'Форель',
    imageAsset: 'assets/fish/trout.png',
    count: 98,
    weightKg: 156.8,
    pricePerKg: 1200,
    remaining: 8,
  ),
];
