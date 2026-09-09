/// Bir koleksiyon ögesinin açılma koşulu türü
/// (bkz. docs/GDD.md, Bölüm 4 - Koleksiyon albümü).
enum UnlockKind { islandLevel, streak }

class Collectible {
  const Collectible({
    required this.id,
    required this.name,
    required this.icon,
    required this.unlockKind,
    required this.unlockValue,
  });

  final String id;
  final String name;
  final String icon;
  final UnlockKind unlockKind;
  final int unlockValue;

  bool isUnlockedFor({required int islandTotalLevel, required int streak}) =>
      switch (unlockKind) {
        UnlockKind.islandLevel => islandTotalLevel >= unlockValue,
        UnlockKind.streak => streak >= unlockValue,
      };

  String get unlockHint => switch (unlockKind) {
    UnlockKind.islandLevel => 'Ada toplam seviye $unlockValue',
    UnlockKind.streak => '$unlockValue günlük seri',
  };
}

/// Toplanabilir dekorasyon/karakter kataloğu. Gerçek sanat varlıkları
/// henüz yok — her öge bir emoji + isimle temsil ediliyor (bkz.
/// docs/GDD.md, Bölüm 7 - Sanat Yönü, ileri fazda gerçek asset'lerle
/// değiştirilecek).
class CollectibleCatalog {
  CollectibleCatalog._();

  static const List<Collectible> all = [
    Collectible(
      id: 'shell',
      name: 'Deniz Kabuğu',
      icon: '🐚',
      unlockKind: UnlockKind.islandLevel,
      unlockValue: 0,
    ),
    Collectible(
      id: 'sapling',
      name: 'Fidan',
      icon: '🌱',
      unlockKind: UnlockKind.islandLevel,
      unlockValue: 2,
    ),
    Collectible(
      id: 'boat',
      name: 'Küçük Yelkenli',
      icon: '⛵',
      unlockKind: UnlockKind.islandLevel,
      unlockValue: 5,
    ),
    Collectible(
      id: 'cactus',
      name: 'Kaktüs',
      icon: '🌵',
      unlockKind: UnlockKind.islandLevel,
      unlockValue: 7,
    ),
    Collectible(
      id: 'camel',
      name: 'Kervan Devesi',
      icon: '🐪',
      unlockKind: UnlockKind.islandLevel,
      unlockValue: 9,
    ),
    Collectible(
      id: 'snowman',
      name: 'Kardan Adam',
      icon: '⛄',
      unlockKind: UnlockKind.islandLevel,
      unlockValue: 10,
    ),
    Collectible(
      id: 'penguin',
      name: 'Penguen',
      icon: '🐧',
      unlockKind: UnlockKind.islandLevel,
      unlockValue: 13,
    ),
    Collectible(
      id: 'rocket',
      name: 'Roket',
      icon: '🚀',
      unlockKind: UnlockKind.islandLevel,
      unlockValue: 15,
    ),
    Collectible(
      id: 'alien',
      name: 'Uzaylı Dost',
      icon: '👽',
      unlockKind: UnlockKind.islandLevel,
      unlockValue: 18,
    ),
    Collectible(
      id: 'streak3',
      name: 'Sadakat Rozeti',
      icon: '🔥',
      unlockKind: UnlockKind.streak,
      unlockValue: 3,
    ),
    Collectible(
      id: 'streak7',
      name: 'Altın Rozet',
      icon: '🏅',
      unlockKind: UnlockKind.streak,
      unlockValue: 7,
    ),
  ];

  static Set<String> unlockedIds({
    required int islandTotalLevel,
    required int streak,
  }) => all
      .where(
        (c) => c.isUnlockedFor(islandTotalLevel: islandTotalLevel, streak: streak),
      )
      .map((c) => c.id)
      .toSet();
}
