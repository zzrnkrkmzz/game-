import 'package:flutter/material.dart';

/// Tahtadaki blokların rengi. Her renk, temizlendiğinde kazanılan kaynak
/// türünü belirler (bkz. docs/GDD.md, Bölüm 2 - Çekirdek Döngü).
enum BlockColor { coral, seafoam, amber }

extension BlockColorX on BlockColor {
  Color get displayColor => switch (this) {
    BlockColor.coral => const Color(0xFFFF8B5E),
    BlockColor.seafoam => const Color(0xFF6FD9C4),
    BlockColor.amber => const Color(0xFFFFC96B),
  };

  ResourceType get resource => switch (this) {
    BlockColor.coral => ResourceType.wood,
    BlockColor.seafoam => ResourceType.stone,
    BlockColor.amber => ResourceType.crystal,
  };
}

/// Ada'da bina inşa etmek için kullanılan kaynak türleri (bkz. Bölüm 3).
enum ResourceType { wood, stone, crystal }

extension ResourceTypeX on ResourceType {
  String get icon => switch (this) {
    ResourceType.wood => '🪵',
    ResourceType.stone => '🪨',
    ResourceType.crystal => '💎',
  };
}
