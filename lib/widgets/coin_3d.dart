import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../models/metal.dart';
import '../theme/app_theme.dart';

/// Настоящая 3D-монета: вращение вокруг вертикальной оси с перспективой,
/// thickness из слоёв, инерция, «магнит» к аверсу/реверсу и металлический блик.
///
/// Управление:
///  • свайп/перетаскивание по горизонтали — вращение;
///  • тап — перевернуть на 180°;
///  • колесо мыши — доводка угла.
class Coin3DView extends StatefulWidget {
  const Coin3DView({
    super.key,
    required this.size,
    required this.metal,
    this.obverse,
    this.reverse,
    this.placeholder = '◎',
    this.showHint = true,
    this.onFaceChanged,
  });

  /// Диаметр монеты в логических пикселях.
  final double size;
  final MetalType metal;
  final Uint8List? obverse;
  final Uint8List? reverse;
  final String placeholder;
  final bool showHint;
  final ValueChanged<CoinFace3D>? onFaceChanged;

  @override
  State<Coin3DView> createState() => _Coin3DViewState();
}

enum CoinFace3D { obverse, reverse }

class _Coin3DViewState extends State<Coin3DView>
    with SingleTickerProviderStateMixin {
  static const double _perspective = 0.0015;
  static const int _rimLayers = 10;

  final ValueNotifier<double> _angle = ValueNotifier<double>(0);
  late final Ticker _ticker;

  double _velocity = 0;
  double? _target;
  Duration _last = Duration.zero;
  bool _dragging = false;
  bool _touched = false;
  CoinFace3D _face = CoinFace3D.obverse;

  double get _depth => widget.size * 0.075;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _angle.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- физика

  void _startTicker() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 0.016
        : (elapsed - _last).inMicroseconds / 1000000.0;
    _last = elapsed;
    final step = dt.clamp(0.0, 0.05);
    if (_dragging) return;

    var a = _angle.value;
    var v = _velocity;
    final target = _target;

    if (target != null) {
      const k = 165.0;
      const c = 24.0;
      v += (-k * (a - target) - c * v) * step;
      a += v * step;
      if ((a - target).abs() < 0.0025 && v.abs() < 0.03) {
        a = target;
        v = 0;
        _target = null;
        _ticker.stop();
      }
    } else {
      a += v * step;
      v *= math.exp(-7.5 * step);
      if (v.abs() < 0.35) {
        v = 0;
        _target = _nearestFace(a);
      }
    }

    _angle.value = a;
    _velocity = v;
    _publishFace(a);
  }

  double _nearestFace(double angle) =>
      (angle / math.pi).roundToDouble() * math.pi;

  void _publishFace(double angle) {
    final back = math.cos(angle) < 0;
    final next = back ? CoinFace3D.reverse : CoinFace3D.obverse;
    if (next != _face) {
      _face = next;
      widget.onFaceChanged?.call(next);
    }
  }

  // ---------------------------------------------------------------- жесты

  void _onDragStart(DragStartDetails _) {
    _dragging = true;
    _target = null;
    _velocity = 0;
    if (_ticker.isActive) _ticker.stop();
    if (!_touched) setState(() => _touched = true);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _angle.value += (details.delta.dx / widget.size) * 3.1;
    _publishFace(_angle.value);
  }

  void _onDragEnd(DragEndDetails details) {
    _dragging = false;
    _velocity = (details.primaryVelocity ?? 0) / widget.size * 3.1;
    _startTicker();
  }

  void _flip() {
    _target = ((_angle.value / math.pi).roundToDouble() + 1) * math.pi;
    _velocity = 0;
    _startTicker();
  }

  void _onScroll(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    _angle.value += event.scrollDelta.dy * 0.005;
    _target = _nearestFace(_angle.value);
    _velocity = 0;
    if (!_touched) setState(() => _touched = true);
    _startTicker();
  }

  // ---------------------------------------------------------------- рендер

  Matrix4 _matrix(double theta, double z) {
    return Matrix4.identity()
      ..setEntry(3, 2, _perspective)
      ..rotateY(theta)
      ..translate(0.0, 0.0, z);
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.size * 1.22;
    return SizedBox(
      width: box,
      height: box,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: <Widget>[
          // Световое пятно софита на бархате.
          Positioned(
            top: box * 0.06,
            child: Container(
              width: widget.size * 1.12,
              height: widget.size * 1.12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    widget.metal.specular.withValues(alpha: 0.10),
                    widget.metal.base.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                  stops: const <double>[0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          Listener(
            onPointerSignal: _onScroll,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _flip,
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              child: RepaintBoundary(
                child: ValueListenableBuilder<double>(
                  valueListenable: _angle,
                  builder: (context, raw, _) {
                    // Приводим угол к (-π, π]: так видимая сторона всегда
                    // остаётся в пределах ±90° и монета «не выворачивается».
                    var angle = raw % (2 * math.pi);
                    if (angle > math.pi) angle -= 2 * math.pi;
                    final showFront = angle.abs() <= math.pi / 2;
                    final faceAngle = showFront
                        ? angle
                        : (angle > 0 ? angle - math.pi : angle + math.pi);
                    final bytes = showFront ? widget.obverse : widget.reverse;
                    final shimmer = math.sin(angle);

                    final layers = <Widget>[
                      // обратная сторона (толщина гурта)
                      Transform(
                        alignment: Alignment.center,
                        transform: _matrix(faceAngle, -_depth),
                        child: _RimDisc(size: widget.size, metal: widget.metal),
                      ),
                      for (var i = _rimLayers; i >= 1; i--)
                        Transform(
                          alignment: Alignment.center,
                          transform: _matrix(
                            faceAngle,
                            -_depth * i / (_rimLayers + 1),
                          ),
                          child: _RimDisc(
                            size: widget.size,
                            metal: widget.metal,
                            edge: true,
                          ),
                        ),
                      // лицевая сторона
                      Transform(
                        alignment: Alignment.center,
                        transform: _matrix(faceAngle, 0),
                        child: _CoinFace(
                          size: widget.size,
                          metal: widget.metal,
                          bytes: bytes,
                          placeholder: widget.placeholder,
                          shimmer: shimmer,
                          mirrored: !showFront,
                        ),
                      ),
                    ];

                    return Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        // контактная тень
                        Positioned(
                          bottom: box * 0.06,
                          child: Container(
                            width: widget.size * 0.72,
                            height: widget.size * 0.12,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              gradient: RadialGradient(
                                colors: <Color>[
                                  Colors.black.withValues(alpha: 0.55),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        ...layers,
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          if (widget.showHint)
            Positioned(
              bottom: 2,
              child: AnimatedOpacity(
                opacity: _touched ? 0 : 1,
                duration: const Duration(milliseconds: 400),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.swipe,
                      size: 14,
                      color: NV.textDim.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'потяните монету',
                      style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1.4,
                        color: NV.textDim.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Диск-слой: имитирует боковую поверхность (гурт) и обратную сторону.
class _RimDisc extends StatelessWidget {
  const _RimDisc({required this.size, required this.metal, this.edge = false});

  final double size;
  final MetalType metal;
  final bool edge;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(0.2, 0.3),
          colors: <Color>[
            Color.lerp(metal.deep, metal.base, edge ? 0.35 : 0.12)!,
            metal.deep,
            Color.lerp(metal.deep, Colors.black, 0.45)!,
          ],
          stops: const <double>[0.0, 0.8, 1.0],
        ),
        border: Border.all(
          color: Color.lerp(metal.deep, Colors.black, 0.3)!,
          width: 0.8,
        ),
      ),
    );
  }
}

/// Лицевая сторона: чеканка, изображение, блик и ободок.
class _CoinFace extends StatelessWidget {
  const _CoinFace({
    required this.size,
    required this.metal,
    required this.bytes,
    required this.placeholder,
    required this.shimmer,
    required this.mirrored,
  });

  final double size;
  final MetalType metal;
  final Uint8List? bytes;
  final String placeholder;
  final double shimmer;
  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    final image = bytes;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.35),
          colors: <Color>[metal.specular, metal.base, metal.deep],
          stops: const <double>[0.0, 0.55, 1.0],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (image != null)
              Transform(
                alignment: Alignment.center,
                transform: mirrored
                    ? (Matrix4.identity()..scale(-1.0, 1.0))
                    : Matrix4.identity(),
                child: Image.memory(
                  image,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                ),
              )
            else
              _PlaceholderBody(metal: metal, text: placeholder, size: size),
            // Блик: две диагональные полосы, ходящие по металлу.
            IgnorePointer(
              child: CustomPaint(
                painter: _SheenPainter(
                  phase: shimmer,
                  color: metal.specular,
                  strength: image == null ? 0.55 : 0.42,
                ),
              ),
            ),
            // Ободок и внутренняя тень — «глубина» рельефа.
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.5,
                    colors: <Color>[
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                    ],
                    stops: const <double>[0.0, 0.86, 1.0],
                  ),
                  border: Border.all(
                    color: metal.specular.withValues(alpha: 0.55),
                    width: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderBody extends StatelessWidget {
  const _PlaceholderBody({
    required this.metal,
    required this.text,
    required this.size,
  });

  final MetalType metal;
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.25, -0.3),
          colors: <Color>[
            metal.specular.withValues(alpha: 0.9),
            metal.base,
            metal.deep,
          ],
          stops: const <double>[0.0, 0.6, 1.0],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              text,
              style: TextStyle(
                fontSize: size * 0.26,
                fontWeight: FontWeight.w700,
                color: metal.deep.withValues(alpha: 0.65),
                letterSpacing: 2,
                shadows: <Shadow>[
                  Shadow(
                    color: metal.specular.withValues(alpha: 0.45),
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
            ),
            SizedBox(height: size * 0.02),
            Text(
              metal.symbol.toUpperCase(),
              style: TextStyle(
                fontSize: size * 0.075,
                letterSpacing: 4,
                fontWeight: FontWeight.w700,
                color: metal.deep.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Металлический блик: движущиеся диагональные полосы, режим plus.
class _SheenPainter extends CustomPainter {
  _SheenPainter({
    required this.phase,
    required this.color,
    required this.strength,
  });

  final double phase;
  final Color color;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));

    final shift = phase * size.width * 0.55;
    final band = Paint()
      ..blendMode = BlendMode.plus
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Colors.transparent,
          color.withValues(alpha: strength * 0.55),
          Colors.white.withValues(alpha: strength),
          color.withValues(alpha: strength * 0.4),
          Colors.transparent,
        ],
        stops: const <double>[0.0, 0.32, 0.5, 0.68, 1.0],
      ).createShader(
        Rect.fromLTWH(shift - size.width * 0.3, -size.height * 0.2,
            size.width * 1.4, size.height * 1.4),
      );
    canvas.drawRect(rect, band);

    // Вторичный узкий блик с обратным ходом — «полировка».
    final second = Paint()
      ..blendMode = BlendMode.plus
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: <Color>[
          Colors.transparent,
          color.withValues(alpha: strength * 0.35),
          Colors.transparent,
        ],
        stops: const <double>[0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromLTWH(-shift - size.width * 0.2, 0, size.width, size.height),
      );
    canvas.drawRect(rect, second);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SheenPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.color != color ||
      oldDelegate.strength != strength;
}
