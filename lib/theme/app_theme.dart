import 'package:flutter/material.dart';

/// Палитра и декоративные примитивы «Тёмной роскоши»:
/// красное дерево, бархат, латунь.
class NV {
  const NV._();

  // Красное дерево (махагон)
  static const Color woodDark = Color(0xFF23120C);
  static const Color wood = Color(0xFF3A1E14);
  static const Color woodLight = Color(0xFF5A2E1F);

  // Бархат
  static const Color velvetGreen = Color(0xFF0E3A2D);
  static const Color velvetGreenDeep = Color(0xFF06201A);
  static const Color burgundy = Color(0xFF4A1220);
  static const Color burgundyDeep = Color(0xFF280A11);

  // Латунь / золото
  static const Color brass = Color(0xFFC9A227);
  static const Color brassLight = Color(0xFFF2DE95);
  static const Color brassDark = Color(0xFF6E5512);
  static const Color patina = Color(0xFF6E8F7A);

  // Текст
  static const Color parchment = Color(0xFFF3E7C9);
  static const Color text = Color(0xFFE7DBC3);
  static const Color textDim = Color(0xFFA99A80);

  static const Color backdrop = Color(0xFF100907);

  static const LinearGradient brassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF7A5E12),
      Color(0xFFE8CE84),
      Color(0xFFC9A227),
      Color(0xFF8A6A17),
      Color(0xFFF0DA94),
    ],
    stops: <double>[0.0, 0.22, 0.5, 0.78, 1.0],
  );

  static const LinearGradient woodGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFF4A2618), Color(0xFF33190F), Color(0xFF23120C)],
  );

  static const RadialGradient velvetGradient = RadialGradient(
    center: Alignment(-0.15, -0.35),
    radius: 1.15,
    colors: <Color>[Color(0xFF14503E), Color(0xFF0B2C24), Color(0xFF04120E)],
  );

  static const RadialGradient burgundyGradient = RadialGradient(
    center: Alignment(-0.2, -0.4),
    radius: 1.2,
    colors: <Color>[Color(0xFF5C1727), Color(0xFF2C0B14), Color(0xFF120509)],
  );

  static ThemeData theme() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: backdrop,
      canvasColor: woodDark,
      colorScheme: const ColorScheme.dark(
        primary: brass,
        onPrimary: Color(0xFF1B1405),
        secondary: brassLight,
        surface: Color(0xFF2A1710),
        onSurface: text,
      ),
      splashColor: brass.withValues(alpha: 0.12),
      highlightColor: brass.withValues(alpha: 0.06),
      textTheme: base.textTheme
          .apply(bodyColor: text, displayColor: parchment)
          .copyWith(
            titleLarge: const TextStyle(
              color: parchment,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
            titleMedium: const TextStyle(
              color: parchment,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            bodyMedium: const TextStyle(color: text, height: 1.35),
            labelSmall: const TextStyle(
              color: textDim,
              fontSize: 11,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF33210F),
        contentTextStyle: TextStyle(color: parchment),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Панель под красное дерево с латунной окантовкой.
  static BoxDecoration woodPanel({double radius = 18, double border = 1.2}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: woodGradient,
      border: Border.all(color: brass.withValues(alpha: 0.45), width: border),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.55),
          blurRadius: 22,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: brassLight.withValues(alpha: 0.07),
          blurRadius: 2,
          offset: const Offset(0, -1),
        ),
      ],
    );
  }

  /// Бархатная подложка (внутренняя часть ящика).
  static BoxDecoration velvetPad({double radius = 14, bool dark = false}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: dark ? burgundyGradient : velvetGradient,
      border: Border.all(color: Colors.black.withValues(alpha: 0.5), width: 1),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static const TextStyle label = TextStyle(
    color: textDim,
    fontSize: 11,
    letterSpacing: 1.8,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle serifTitle = TextStyle(
    color: parchment,
    fontSize: 19,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    height: 1.2,
  );

  static TextStyle brassText({double size = 12, double spacing = 2.4}) =>
      TextStyle(
        fontSize: size,
        letterSpacing: spacing,
        fontWeight: FontWeight.w700,
        color: brassLight,
      );

  /// Текст «выгравирован» в металле — тёмный со светлой нижней тенью.
  static TextStyle engraved({double size = 16, FontWeight weight = FontWeight.w600}) =>
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: const Color(0xFF2A1A08),
        shadows: <Shadow>[
          Shadow(
            color: brassLight.withValues(alpha: 0.35),
            offset: const Offset(0, 1),
          ),
        ],
      );
}
