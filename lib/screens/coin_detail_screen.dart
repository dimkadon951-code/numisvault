import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/coin_store.dart';
import '../models/coin.dart';
import '../theme/app_theme.dart';
import '../widgets/coin_3d.dart';
import '../widgets/ui_kit.dart';
import '../widgets/velvet.dart';
import 'edit_coin_screen.dart';

/// Экран детального 3D-просмотра монеты.
class CoinDetailScreen extends StatefulWidget {
  const CoinDetailScreen({
    super.key,
    required this.store,
    required this.coinId,
  });

  final CoinStore store;
  final String coinId;

  @override
  State<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends State<CoinDetailScreen> {
  CoinFace3D _face = CoinFace3D.obverse;
  Offset? _pointer;

  Coin? get _coin {
    for (final coin in widget.store.coins) {
      if (coin.id == widget.coinId) return coin;
    }
    return null;
  }

  Future<void> _delete(Coin coin) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF2A1710),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: NV.brass.withValues(alpha: 0.4)),
        ),
        title: const Text(
          'Удалить монету?',
          style: TextStyle(color: NV.parchment, fontSize: 17),
        ),
        content: Text(
          '«${coin.title.isEmpty ? 'Без названия' : coin.title}» будет удалена '
          'из коллекции на всех устройствах.',
          style: const TextStyle(color: NV.textDim, fontSize: 13.5, height: 1.4),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена', style: TextStyle(color: NV.textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Удалить',
              style: TextStyle(color: Color(0xFFE08A9A), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await widget.store.delete(coin.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NV.backdrop,
      body: VaultBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: widget.store,
            builder: (context, _) {
              final coin = _coin;
              if (coin == null) {
                return const Center(
                  child: Text(
                    'Монета удалена',
                    style: TextStyle(color: NV.textDim),
                  ),
                );
              }
              final obverse = widget.store.image(coin.id, CoinFace.obverse);
              final reverse = widget.store.image(coin.id, CoinFace.reverse);
              final media = MediaQuery.of(context).size;
              final coinSize = (media.width * 0.62).clamp(180.0, 340.0);

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: CustomScrollView(
                    slivers: <Widget>[
                      SliverToBoxAdapter(child: _topBar(coin)),
                      SliverToBoxAdapter(
                        child: _stage(
                          coin: coin,
                          obverse: obverse,
                          reverse: reverse,
                          size: coinSize,
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 30),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate(<Widget>[
                            _plaque(coin),
                            const SizedBox(height: 14),
                            _specs(coin),
                            const SizedBox(height: 14),
                            _descriptions(coin),
                            const SizedBox(height: 18),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: BrassButton(
                                    label: 'Изменить',
                                    icon: Icons.edit_outlined,
                                    dark: true,
                                    expand: true,
                                    onTap: () => EditCoinScreen.open(
                                      context,
                                      widget.store,
                                      coin: coin,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                BrassButton(
                                  label: 'Удалить',
                                  icon: Icons.delete_outline,
                                  dark: true,
                                  dense: true,
                                  onTap: () => _delete(coin),
                                ),
                              ],
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _topBar(Coin coin) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Row(
        children: <Widget>[
          BrassIconButton(
            icon: Icons.arrow_back,
            tooltip: 'Назад',
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('ВИТРИНА · 3D', style: NV.label),
                const SizedBox(height: 2),
                Text(
                  coin.title.isEmpty ? 'Монета' : coin.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: NV.parchment,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          BrassIconButton(
            icon: _face == CoinFace3D.obverse
                ? Icons.rotate_90_degrees_cw
                : Icons.rotate_90_degrees_ccw,
            tooltip: _face == CoinFace3D.obverse ? 'Показан аверс' : 'Показан реверс',
            onTap: () => setState(() {
              _face = _face == CoinFace3D.obverse
                  ? CoinFace3D.reverse
                  : CoinFace3D.obverse;
            }),
          ),
        ],
      ),
    );
  }

  Widget _stage({
    required Coin coin,
    required Uint8List? obverse,
    required Uint8List? reverse,
    required double size,
  }) {
    const loupe = 120.0;
    return SizedBox(
      height: size * 1.30 + 34,
      child: MouseRegion(
        onHover: (event) => setState(() => _pointer = event.localPosition),
        onExit: (_) {
          if (_pointer != null) setState(() => _pointer = null);
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return Stack(
              alignment: Alignment.center,
              children: <Widget>[
                // Бархатная тумба-подставка.
                Positioned(
                  bottom: 16,
                  child: Container(
                    width: size * 1.32,
                    height: size * 0.30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(size),
                      gradient: const RadialGradient(
                        colors: <Color>[Color(0xFF1B0E09), Color(0xFF080403)],
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.65),
                          blurRadius: 26,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                  ),
                ),
                Coin3DView(
                  size: size,
                  metal: coin.metal,
                  obverse: obverse,
                  reverse: reverse,
                  placeholder: _initial(coin),
                  onFaceChanged: (face) {
                    if (face != _face) setState(() => _face = face);
                  },
                ),
                Positioned(
                  bottom: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _faceBadge('АВЕРС', _face == CoinFace3D.obverse),
                      const SizedBox(width: 8),
                      _faceBadge('РЕВЕРС', _face == CoinFace3D.reverse),
                    ],
                  ),
                ),
                // Лупа для мыши: увеличение деталей.
                if (_pointer != null)
                  Positioned(
                    left: (_pointer!.dx - loupe / 2)
                        .clamp(0.0, (width - loupe).clamp(0.0, width)),
                    top: (_pointer!.dy - loupe - 40).clamp(0.0, size * 1.3),
                    child: IgnorePointer(
                      child: RawMagnifier(
                        size: const Size(loupe, loupe),
                        magnificationScale: 2.1,
                        focalPointOffset: const Offset(0, loupe + 40),
                        decoration: const MagnifierDecoration(
                          shape: CircleBorder(
                            side: BorderSide(color: NV.brass, width: 2),
                          ),
                        ),
                        child: const SizedBox.shrink(),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _initial(Coin coin) {
    final text = coin.title.trim();
    if (text.isEmpty) return '◎';
    return String.fromCharCode(text.runes.first).toUpperCase();
  }

  Widget _faceBadge(String label, bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: active ? NV.brassGradient : null,
        color: active ? null : Colors.black.withValues(alpha: 0.35),
        border: Border.all(
          color: active
              ? NV.brassDark
              : NV.brass.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w800,
          color: active ? const Color(0xFF2A1D05) : NV.textDim,
        ),
      ),
    );
  }

  Widget _plaque(Coin coin) {
    return WoodPanel(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionTitle(
            text: 'Номинал / название',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: NV.brassGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                coin.grade.short,
                style: const TextStyle(
                  color: Color(0xFF2A1D05),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            coin.title.isEmpty ? 'Без названия' : coin.title,
            style: const TextStyle(
              color: NV.parchment,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${coin.countryLabel} · ${coin.yearLabel} · ${coin.metal.label}',
            style: const TextStyle(color: NV.textDim, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _specs(Coin coin) {
    String num(double? value, String unit) =>
        value == null ? '—' : '${value.toString().replaceAll('.', ',')} $unit';

    return WoodPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionTitle(text: 'Характеристики'),
          const BrassDivider(),
          SpecRow(label: 'Страна', value: coin.countryLabel),
          SpecRow(label: 'Год выпуска', value: coin.yearLabel),
          SpecRow(
            label: 'Монетный двор',
            value: coin.mint.trim().isEmpty ? '—' : coin.mint,
          ),
          SpecRow(
            label: 'Металл',
            value: coin.fineness.trim().isEmpty
                ? coin.metal.label
                : '${coin.metal.label} · проба ${coin.fineness}',
          ),
          SpecRow(label: 'Вес', value: num(coin.weight, 'г'), monospace: true),
          SpecRow(label: 'Диаметр', value: num(coin.diameter, 'мм'), monospace: true),
          SpecRow(
            label: 'Тираж',
            value: coin.mintage.trim().isEmpty ? '—' : coin.mintage,
            monospace: true,
          ),
          SpecRow(label: 'Сохранность', value: coin.grade.full),
        ],
      ),
    );
  }

  Widget _descriptions(Coin coin) {
    return WoodPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionTitle(text: 'Описание сторон'),
          const SizedBox(height: 10),
          _descBlock('Аверс', coin.obverseDescription),
          const BrassDivider(),
          _descBlock('Реверс', coin.reverseDescription),
        ],
      ),
    );
  }

  Widget _descBlock(String title, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: NV.brass,
              ),
            ),
            const SizedBox(width: 7),
            Text(title.toUpperCase(), style: NV.label),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          text.trim().isEmpty ? 'Описание не заполнено' : text,
          style: TextStyle(
            color: text.trim().isEmpty ? NV.textDim : NV.parchment,
            fontSize: 13.5,
            height: 1.5,
            fontStyle: text.trim().isEmpty ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );
  }
}
