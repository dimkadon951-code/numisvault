import 'package:flutter/material.dart';

/// Металл монеты. От него зависит цвет 3D-блика и градиент "чеканки".
enum MetalType {
  gold('Золото', 'Au', Color(0xFFEFC24C), Color(0xFFFFF6D0), Color(0xFF7E5A10)),
  silver('Серебро', 'Ag', Color(0xFFD7D9DE), Color(0xFFFFFFFF), Color(0xFF666B72)),
  platinum('Платина', 'Pt', Color(0xFFCBD3DC), Color(0xFFF7FAFF), Color(0xFF565F6B)),
  palladium('Палладий', 'Pd', Color(0xFFBFC3C6), Color(0xFFF0F2F3), Color(0xFF52575A)),
  copper('Медь', 'Cu', Color(0xFFC06A3E), Color(0xFFFFCDAB), Color(0xFF5F2410)),
  bronze('Бронза', 'Br', Color(0xFFA9834A), Color(0xFFEFDAA8), Color(0xFF443317)),
  brass('Латунь', 'Lt', Color(0xFFD3B055), Color(0xFFFFEFB8), Color(0xFF5E4913)),
  nickel('Никель', 'Ni', Color(0xFFC2C7CB), Color(0xFFF4F7F9), Color(0xFF52575B)),
  bimetal('Биметалл', 'Bi', Color(0xFFDCC078), Color(0xFFFFFFFF), Color(0xFF41525D));

  const MetalType(this.label, this.symbol, this.base, this.specular, this.deep);

  final String label;
  final String symbol;

  /// Основной тон металла.
  final Color base;

  /// Цвет зеркального блика.
  final Color specular;

  /// Тень/гурт.
  final Color deep;

  static MetalType parse(String? raw) {
    if (raw == null) return MetalType.silver;
    for (final m in MetalType.values) {
      if (m.name == raw) return m;
    }
    return MetalType.silver;
  }
}

/// Сохранность монеты (международная шкала).
enum Grade {
  g('G', 'Good', 'Плохая'),
  vg('VG', 'Very Good', 'Удовлетворительная'),
  f('F', 'Fine', 'Средняя'),
  vf('VF', 'Very Fine', 'Хорошая'),
  xf('XF', 'Extremely Fine', 'Отличная'),
  au('AU', 'About Uncirculated', 'Почти превосходная'),
  unc('UNC', 'Uncirculated', 'Превосходная (без оборота)'),
  proof('PROOF', 'Proof', 'Пруф');

  const Grade(this.short, this.en, this.ru);

  final String short;
  final String en;
  final String ru;

  String get full => '$short · $ru';

  static Grade parse(String? raw) {
    if (raw == null) return Grade.vf;
    for (final g in Grade.values) {
      if (g.name == raw) return g;
    }
    return Grade.vf;
  }
}
