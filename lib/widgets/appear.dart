import 'package:flutter/material.dart';

/// Появление элемента «из бархатного ящика»: лёгкий подъём,
/// наклон по оси X и проявление. Задержка задаётся по индексу.
class Appear extends StatefulWidget {
  const Appear({
    super.key,
    required this.child,
    this.index = 0,
    this.delayMs = 45,
    this.duration = const Duration(milliseconds: 420),
    this.offsetY = 26,
    this.tilt = 0.09,
  });

  final Widget child;
  final int index;
  final int delayMs;
  final Duration duration;
  final double offsetY;
  final double tilt;

  @override
  State<Appear> createState() => _AppearState();
}

class _AppearState extends State<Appear> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: widget.index * widget.delayMs), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final curved = widget.duration;
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: curved,
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : Offset(0, widget.offsetY / 300),
        duration: curved,
        curve: Curves.easeOutCubic,
        child: AnimatedScale(
          scale: _visible ? 1 : 0.94,
          duration: curved,
          curve: Curves.easeOutBack,
          child: _TiltReveal(
            visible: _visible,
            tilt: widget.tilt,
            duration: curved,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _TiltReveal extends StatelessWidget {
  const _TiltReveal({
    required this.visible,
    required this.tilt,
    required this.duration,
    required this.child,
  });

  final bool visible;
  final double tilt;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: tilt, end: visible ? 0 : tilt),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateX(value),
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Переход «выдвигается бархатный ящик» — для смены разделов/фильтров.
class VelvetDrawerTransition extends StatelessWidget {
  const VelvetDrawerTransition({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 430),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.expand,
        children: <Widget>[...previous, if (current != null) current],
      ),
      transitionBuilder: (child, animation) {
        final isIncoming = child.key != null;
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(curved),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0, isIncoming ? 0.16 : -0.06),
              end: Offset.zero,
            ).animate(curved),
            child: Transform(
              alignment: Alignment.topCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0014)
                ..rotateX((1 - curved.value) * (isIncoming ? 0.20 : -0.10)),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}
