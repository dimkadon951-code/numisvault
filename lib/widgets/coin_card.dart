import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/coin.dart';
import '../models/metal.dart';
import '../theme/app_theme.dart';

/// Витринная карточка монеты: бархатная подушка, латунная окантовка,
/// круглая монета с бликом и лёгким наклоном при наведении.
class CoinCard extends StatefulWidget {
  const CoinCard({
    super.key,
    required this.coin,
    required this.obverse,
    this.onTap,
  });

  final Coin coin;
  final Uint8List? obverse;
  final VoidCallback? onTap;

  @override
  State<CoinCard> createState() => _CoinCardState();
}

class _CoinCardState extends State<CoinCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final coin = widget.coin;
    final metal = coin.metal;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hover ? 1.025 : 1.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: NV.woodPanel(radius: 16),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: Container(
                    decoration: NV.velvetPad(radius: 12),
                    child: Center(
                      child: AnimatedScale(
                        scale: _hover ? 1.08 : 1.0,
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutBack,
                        child: _CoinThumb(bytes: widget.obverse, metal: metal),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  coin.title.isEmpty ? 'Без названия' : coin.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: NV.parchment,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${coin.countryLabel} · ${coin.yearLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: NV.textDim,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    _MetalDot(color: metal.base),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: NV.brass.withValues(alpha: 0.22),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '${metal.label.toUpperCase()} · ${coin.grade.short}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: NV.brassLight,
                      fontSize: 9.5,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetalDot extends StatelessWidget {
  const _MetalDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[color, Color.lerp(color, Colors.black, 0.45)!],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 5),
        ],
      ),
    );
  }
}

/// Круглая миниатюра монеты с имитацией металла и блика.
class _CoinThumb extends StatelessWidget {
  const _CoinThumb({required this.bytes, required this.metal});

  final Uint8List? bytes;
  final MetalType metal;

  @override
  Widget build(BuildContext context) {
    final bytes = this.bytes;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.35, -0.45),
            colors: <Color>[
              metal.specular,
              metal.base,
              metal.deep,
            ],
            stops: const <double>[0.0, 0.62, 1.0],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: metal.specular.withValues(alpha: 0.18),
              blurRadius: 14,
            ),
          ],
          border: Border.all(
            color: metal.deep.withValues(alpha: 0.85),
            width: 1.4,
          ),
        ),
        child: bytes == null
            ? Center(
                child: Icon(
                  Icons.paid_outlined,
                  size: 26,
                  color: metal.deep.withValues(alpha: 0.85),
                ),
              )
            : ClipOval(
                child: Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                ),
              ),
      ),
    );
  }
}
