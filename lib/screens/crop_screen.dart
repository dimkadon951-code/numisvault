import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';
import '../widgets/velvet.dart';

/// Ручная подгонка круглого выреза.
///
/// На выходе — PNG ровно по кругу с прозрачным фоном, поэтому при 3D-вращении
/// монета выглядит настоящей, без квадратной подложки.
class RoundCropScreen extends StatefulWidget {
  const RoundCropScreen({
    super.key,
    required this.bytes,
    required this.title,
    required this.accent,
  });

  final Uint8List bytes;
  final String title;
  final Color accent;

  static Future<Uint8List?> open(
    BuildContext context, {
    required Uint8List bytes,
    required String title,
    required Color accent,
  }) {
    return Navigator.of(context).push<Uint8List>(
      MaterialPageRoute<Uint8List>(
        fullscreenDialog: true,
        builder: (_) => RoundCropScreen(
          bytes: bytes,
          title: title,
          accent: accent,
        ),
      ),
    );
  }

  @override
  State<RoundCropScreen> createState() => _RoundCropScreenState();
}

class _RoundCropScreenState extends State<RoundCropScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  ui.Image? _image;
  String? _error;

  double _scale = 1.0;
  double _startScale = 1.0;
  Offset _offset = Offset.zero;
  Offset _startOffset = Offset.zero;
  Offset _startFocal = Offset.zero;
  double _side = 320;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  Future<void> _decode() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.bytes);
      final frame = await codec.getNextFrame();
      if (!mounted) return;
      setState(() => _image = frame.image);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Не удалось прочитать изображение');
    }
  }

  double get _maxShift => (_side * (_scale - 1)) / 2;

  void _clampOffset() {
    final maxShift = _maxShift;
    _offset = Offset(
      _offset.dx.clamp(-maxShift, maxShift),
      _offset.dy.clamp(-maxShift, maxShift),
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _startScale = _scale;
    _startOffset = _offset;
    _startFocal = details.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_startScale * details.scale).clamp(1.0, 4.0);
      _offset = _startOffset + (details.localFocalPoint - _startFocal);
      _clampOffset();
    });
  }

  void _zoomBy(double delta) {
    setState(() {
      _scale = (_scale + delta).clamp(1.0, 4.0);
      _clampOffset();
    });
  }

  void _onScroll(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      _zoomBy(-event.scrollDelta.dy * 0.0016);
    }
  }

  Future<Uint8List?> _capture() async {
    final boundary =
        _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    Uint8List? smallest;
    for (final pixels in const <double>[760, 600, 480, 360, 280]) {
      final image = await boundary.toImage(pixelRatio: pixels / _side);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) continue;
      final bytes = Uint8List.fromList(data.buffer.asUint8List());
      smallest = bytes;
      if (bytes.lengthInBytes <= 700 * 1024) return bytes;
    }
    return smallest;
  }

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await _capture();
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return Scaffold(
      backgroundColor: NV.backdrop,
      body: VaultBackground(
        burgundy: true,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                child: Row(
                  children: <Widget>[
                    BrassIconButton(
                      icon: Icons.close,
                      tooltip: 'Отмена',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(widget.title.toUpperCase(), style: NV.label),
                          const SizedBox(height: 2),
                          const Text(
                            'Подгоните монету в круг',
                            style: TextStyle(
                              color: NV.parchment,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: image == null
                      ? (_error == null
                          ? const CircularProgressIndicator(
                              color: NV.brass,
                              strokeWidth: 2,
                            )
                          : Text(
                              _error!,
                              style: const TextStyle(color: NV.textDim),
                            ))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            _side = math.min(
                              constraints.maxWidth * 0.86,
                              constraints.maxHeight * 0.9,
                            );
                            return SizedBox(
                              width: _side + 72,
                              height: _side + 72,
                              child: Stack(
                                alignment: Alignment.center,
                                children: <Widget>[
                                  // Подложка «лупы» — вне RepaintBoundary.
                                  Container(
                                    width: _side + 60,
                                    height: _side + 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: <Color>[
                                          NV.wood,
                                          Colors.black.withValues(alpha: 0.85),
                                        ],
                                      ),
                                      boxShadow: <BoxShadow>[
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          blurRadius: 30,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Listener(
                                    onPointerSignal: _onScroll,
                                    child: GestureDetector(
                                      onScaleStart: _onScaleStart,
                                      onScaleUpdate: _onScaleUpdate,
                                      child: RepaintBoundary(
                                        key: _boundaryKey,
                                        child: ClipOval(
                                          child: SizedBox(
                                            width: _side,
                                            height: _side,
                                            child: Transform.translate(
                                              offset: _offset,
                                              child: Transform.scale(
                                                scale: _scale,
                                                child: SizedBox(
                                                  width: _side,
                                                  height: _side,
                                                  child: FittedBox(
                                                    fit: BoxFit.cover,
                                                    clipBehavior: Clip.hardEdge,
                                                    child: SizedBox(
                                                      width: image.width.toDouble(),
                                                      height: image.height.toDouble(),
                                                      child: RawImage(
                                                        image: image,
                                                        fit: BoxFit.fill,
                                                        filterQuality:
                                                            FilterQuality.high,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Латунное кольцо-оправа (не попадает в снимок).
                                  IgnorePointer(
                                    child: Container(
                                      width: _side,
                                      height: _side,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: NV.brass.withValues(alpha: 0.85),
                                          width: 2.2,
                                        ),
                                        boxShadow: <BoxShadow>[
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.55),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                          BoxShadow(
                                            color: NV.brassLight.withValues(alpha: 0.18),
                                            blurRadius: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        BrassIconButton(
                          icon: Icons.zoom_out,
                          tooltip: 'Уменьшить',
                          onTap: () => _zoomBy(-0.2),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: NV.brass.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '${(_scale * 100).round()}%',
                            style: const TextStyle(
                              color: NV.parchment,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        BrassIconButton(
                          icon: Icons.zoom_in,
                          tooltip: 'Увеличить',
                          onTap: () => _zoomBy(0.2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Тяните фото, чтобы совместить центр монеты с кругом',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: NV.textDim.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: BrassButton(
                            label: 'Отмена',
                            dark: true,
                            expand: true,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: BrassButton(
                            label: _busy ? 'Обработка…' : 'Готово',
                            icon: Icons.check,
                            expand: true,
                            onTap: _busy ? null : _confirm,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
