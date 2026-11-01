import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Фон приложения: бархат в глубине, дерево по краям, латунная виньетка.
class VaultBackground extends StatelessWidget {
  const VaultBackground({
    super.key,
    required this.child,
    this.burgundy = false,
    this.woodEdges = true,
  });

  final Widget child;
  final bool burgundy;
  final bool woodEdges;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: burgundy ? NV.burgundyGradient : NV.velvetGradient,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          RepaintBoundary(
            child: CustomPaint(
              painter: _VelvetPainter(burgundy: burgundy),
              isComplex: true,
            ),
          ),
          if (woodEdges)
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(painter: _FramePainter()),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _VelvetPainter extends CustomPainter {
  _VelvetPainter({required this.burgundy});

  final bool burgundy;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final random = math.Random(burgundy ? 4242 : 1711);
    final paint = Paint();
    // Ворс: мягкие пятна света и тени.
    for (var i = 0; i < 260; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final radius = 4 + random.nextDouble() * 46;
      final light = random.nextBool();
      paint.color = (light ? Colors.white : Colors.black)
          .withValues(alpha: light ? 0.008 + random.nextDouble() * 0.015 : 0.02 + random.nextDouble() * 0.03);
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
    // Виньетка по краям.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.95,
          colors: <Color>[
            Colors.transparent,
            Colors.black.withValues(alpha: 0.45),
            Colors.black.withValues(alpha: 0.75),
          ],
          stops: const <double>[0.45, 0.85, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _VelvetPainter oldDelegate) =>
      oldDelegate.burgundy != burgundy;
}

/// Тёмное дерево по периметру экрана + латунная полоска.
class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final edge = math.min(size.width, size.height) * 0.028;
    final framePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFF4A2618), Color(0xFF2A150D), Color(0xFF1A0C07)],
      ).createShader(rect);
    final path = Path()
      ..addRect(rect)
      ..addRect(rect.deflate(edge))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, framePaint);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = NV.brass.withValues(alpha: 0.35);
    canvas.drawRect(rect.deflate(edge), line);
    canvas.drawRect(
      rect.deflate(edge * 0.55),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.black.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(covariant _FramePainter oldDelegate) => false;
}

/// Панель «красное дерево» с волокнами и латунными уголками.
class WoodPanel extends StatelessWidget {
  const WoodPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
    this.screws = true,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final bool screws;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final panel = DecoratedBox(
      decoration: NV.woodPanel(radius: radius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(painter: _WoodGrainPainter()),
              ),
            ),
            Padding(padding: padding, child: child),
            if (screws) ...<Widget>[
              Positioned(left: 7, top: 7, child: _Screw()),
              Positioned(right: 7, top: 7, child: _Screw()),
              Positioned(left: 7, bottom: 7, child: _Screw()),
              Positioned(right: 7, bottom: 7, child: _Screw()),
            ],
          ],
        ),
      ),
    );
    if (onTap == null) return panel;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: panel,
    );
  }
}

class _Screw extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFE8CE84), Color(0xFF8A6A17)],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

class _WoodGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(97);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var i = 0; i < 26; i++) {
      final y = random.nextDouble() * size.height;
      final wave = 3 + random.nextDouble() * 10;
      final path = Path()..moveTo(-10, y);
      for (double x = 0; x <= size.width + 10; x += 18) {
        path.lineTo(x, y + math.sin((x / size.width) * math.pi * 2 + i) * wave * 0.3);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6 + random.nextDouble() * 1.4
          ..color = (random.nextBool() ? Colors.black : const Color(0xFF6B3320))
              .withValues(alpha: 0.10 + random.nextDouble() * 0.10),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WoodGrainPainter oldDelegate) => false;
}

/// Бархатная подушечка (для карточек/секций).
class VelvetPad extends StatelessWidget {
  const VelvetPad({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 14,
    this.dark = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: NV.velvetPad(radius: radius, dark: dark),
      child: child,
    );
  }
}

/// Тонкая латунная линия-разделитель.
class BrassDivider extends StatelessWidget {
  const BrassDivider({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: indent),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            NV.brass.withValues(alpha: 0),
            NV.brass.withValues(alpha: 0.55),
            NV.brass.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
