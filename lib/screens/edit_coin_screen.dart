import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/coin_store.dart';
import '../models/coin.dart';
import '../models/metal.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';
import '../widgets/velvet.dart';
import 'crop_screen.dart';

/// Экран добавления и редактирования монеты.
class EditCoinScreen extends StatefulWidget {
  const EditCoinScreen({super.key, required this.store, this.coin});

  final CoinStore store;
  final Coin? coin;

  static Future<bool?> open(BuildContext context, CoinStore store, {Coin? coin}) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EditCoinScreen(store: store, coin: coin),
      ),
    );
  }

  @override
  State<EditCoinScreen> createState() => _EditCoinScreenState();
}

class _EditCoinScreenState extends State<EditCoinScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _country;
  late final TextEditingController _year;
  late final TextEditingController _mint;
  late final TextEditingController _fineness;
  late final TextEditingController _weight;
  late final TextEditingController _diameter;
  late final TextEditingController _mintage;
  late final TextEditingController _obverseDesc;
  late final TextEditingController _reverseDesc;

  late MetalType _metal;
  late Grade _grade;
  Uint8List? _obverse;
  Uint8List? _reverse;
  bool _saving = false;

  bool get _isEdit => widget.coin != null;

  @override
  void initState() {
    super.initState();
    final c = widget.coin;
    _title = TextEditingController(text: c?.title ?? '');
    _country = TextEditingController(text: c?.country ?? '');
    _year = TextEditingController(text: c?.year?.toString() ?? '');
    _mint = TextEditingController(text: c?.mint ?? '');
    _fineness = TextEditingController(text: c?.fineness ?? '');
    _weight = TextEditingController(text: c?.weight?.toString() ?? '');
    _diameter = TextEditingController(text: c?.diameter?.toString() ?? '');
    _mintage = TextEditingController(text: c?.mintage ?? '');
    _obverseDesc = TextEditingController(text: c?.obverseDescription ?? '');
    _reverseDesc = TextEditingController(text: c?.reverseDescription ?? '');
    _metal = c?.metal ?? MetalType.silver;
    _grade = c?.grade ?? Grade.vf;
    if (c != null) {
      _obverse = widget.store.image(c.id, CoinFace.obverse);
      _reverse = widget.store.image(c.id, CoinFace.reverse);
    }
  }

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      _title,
      _country,
      _year,
      _mint,
      _fineness,
      _weight,
      _diameter,
      _mintage,
      _obverseDesc,
      _reverseDesc,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  double? _parse(double? fallback, String raw) {
    final cleaned = raw.replaceAll(',', '.').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned) ?? fallback;
  }

  // ------------------------------------------------------------------- фото

  Future<void> _pickPhoto(CoinFace face) async {
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: NV.woodPanel(radius: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
              child: Row(
                children: <Widget>[
                  Text(
                    face == CoinFace.obverse ? 'ФОТО АВЕРСА' : 'ФОТО РЕВЕРСА',
                    style: NV.label,
                  ),
                ],
              ),
            ),
            if (isMobile)
              _SheetTile(
                icon: Icons.photo_camera_outlined,
                label: 'Снять на камеру',
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
            _SheetTile(
              icon: Icons.photo_library_outlined,
              label: 'Выбрать из файлов',
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            if (face == CoinFace.obverse || face == CoinFace.reverse)
              _SheetTile(
                icon: Icons.delete_outline,
                label: 'Убрать фото',
                danger: true,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  setState(() {
                    if (face == CoinFace.obverse) {
                      _obverse = null;
                    } else {
                      _reverse = null;
                    }
                  });
                },
              ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final XFile? file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2400,
        imageQuality: 92,
      );
      if (file == null) return;
      final raw = await file.readAsBytes();
      if (!mounted) return;
      final cropped = await RoundCropScreen.open(
        context,
        bytes: raw,
        title: face == CoinFace.obverse ? 'Аверс' : 'Реверс',
        accent: _metal.base,
      );
      if (cropped == null || !mounted) return;
      setState(() {
        if (face == CoinFace.obverse) {
          _obverse = cropped;
        } else {
          _reverse = cropped;
        }
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось открыть изображение: $error')),
      );
    }
  }

  // ------------------------------------------------------------------- save

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final existing = widget.coin;
    final coin = Coin(
      id: existing?.id ?? CoinStore.newId(),
      title: _title.text.trim(),
      country: _country.text.trim(),
      year: int.tryParse(_year.text.trim()),
      mint: _mint.text.trim(),
      metal: _metal,
      fineness: _fineness.text.trim(),
      obverseDescription: _obverseDesc.text.trim(),
      reverseDescription: _reverseDesc.text.trim(),
      weight: _parse(existing?.weight, _weight.text),
      diameter: _parse(existing?.diameter, _diameter.text),
      mintage: _mintage.text.trim(),
      grade: _grade,
      updatedAt: DateTime.now(),
    );

    await widget.store.save(coin, obverse: _obverse, reverse: _reverse);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(true);
  }

  // ------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NV.backdrop,
      body: VaultBackground(
        burgundy: true,
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
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
                            Text(
                              _isEdit ? 'РЕДАКТИРОВАНИЕ' : 'НОВАЯ МОНЕТА',
                              style: NV.label,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isEdit
                                  ? (widget.coin!.title.isEmpty
                                      ? 'Монета'
                                      : widget.coin!.title)
                                  : 'Пополнение коллекции',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: NV.parchment,
                                fontSize: 17,
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
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                    children: <Widget>[
                      _photos(),
                      const SizedBox(height: 14),
                      WoodPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const SectionTitle(text: 'Идентификация'),
                            const SizedBox(height: 12),
                            NVField(
                              label: 'Название / номинал',
                              hint: '1 рубль «Соболь»',
                              controller: _title,
                              textCapitalization: TextCapitalization.sentences,
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                      ? 'Укажите название или номинал'
                                      : null,
                            ),
                            const SizedBox(height: 12),
                            NVField(
                              label: 'Страна',
                              hint: 'Российская империя',
                              controller: _country,
                              textCapitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: NVField(
                                    label: 'Год',
                                    hint: '1899',
                                    controller: _year,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      final raw = value?.trim() ?? '';
                                      if (raw.isEmpty) return null;
                                      final year = int.tryParse(raw);
                                      if (year == null || year < 500 || year > 2100) {
                                        return 'Год 500–2100';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: NVField(
                                    label: 'Монетный двор',
                                    hint: 'СПб, ММД, ЛМД…',
                                    controller: _mint,
                                    textCapitalization: TextCapitalization.characters,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      WoodPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const SectionTitle(text: 'Металл и физика'),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: NVDropdown<MetalType>(
                                    label: 'Металл',
                                    value: _metal,
                                    items: MetalType.values,
                                    itemLabel: (m) => '${m.label} (${m.symbol})',
                                    onChanged: (value) =>
                                        setState(() => _metal = value),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: NVField(
                                    label: 'Проба',
                                    hint: '925',
                                    controller: _fineness,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: NVField(
                                    label: 'Вес, г',
                                    hint: '20,0',
                                    controller: _weight,
                                    keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: NVField(
                                    label: 'Диаметр, мм',
                                    hint: '33,5',
                                    controller: _diameter,
                                    keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: NVField(
                                    label: 'Тираж',
                                    hint: '500 000',
                                    controller: _mintage,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: NVDropdown<Grade>(
                                    label: 'Сохранность',
                                    value: _grade,
                                    items: Grade.values,
                                    itemLabel: (g) => '${g.short} · ${g.ru}',
                                    onChanged: (value) =>
                                        setState(() => _grade = value),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      WoodPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const SectionTitle(text: 'Описание сторон'),
                            const SizedBox(height: 12),
                            NVField(
                              label: 'Что изображено на аверсе',
                              hint: 'Портрет императора в профиль, круговая надпись…',
                              controller: _obverseDesc,
                              maxLines: 4,
                            ),
                            const SizedBox(height: 12),
                            NVField(
                              label: 'Что изображено на реверсе',
                              hint: 'Герб, номинал в венке, дата…',
                              controller: _reverseDesc,
                              maxLines: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
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
                            flex: 2,
                            child: BrassButton(
                              label: _saving
                                  ? 'Сохранение…'
                                  : (_isEdit ? 'Сохранить изменения' : 'Добавить в коллекцию'),
                              icon: Icons.check,
                              expand: true,
                              onTap: _saving ? null : _save,
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
      ),
    );
  }

  Widget _photos() {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final coinId = widget.coin?.id;
        final existingObverse = _obverse ??
            (coinId == null ? null : widget.store.image(coinId, CoinFace.obverse));
        final existingReverse = _reverse ??
            (coinId == null ? null : widget.store.image(coinId, CoinFace.reverse));
        return WoodPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SectionTitle(text: 'Фотографии'),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _PhotoSlot(
                      label: 'Аверс',
                      bytes: existingObverse,
                      metal: _metal,
                      onTap: () => _pickPhoto(CoinFace.obverse),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _PhotoSlot(
                      label: 'Реверс',
                      bytes: existingReverse,
                      metal: _metal,
                      onTap: () => _pickPhoto(CoinFace.reverse),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Фото автоматически обрезается по кругу — при вращении монета выглядит настоящей.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  color: NV.textDim.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: <Widget>[
            Icon(
              icon,
              size: 18,
              color: danger ? const Color(0xFFE08A9A) : NV.brassLight,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: danger ? const Color(0xFFE08A9A) : NV.text,
                fontSize: 14.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    required this.label,
    required this.bytes,
    required this.metal,
    required this.onTap,
  });

  final String label;
  final Uint8List? bytes;
  final MetalType metal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final data = bytes;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.4),
                  colors: <Color>[metal.specular, metal.base, metal.deep],
                  stops: const <double>[0.0, 0.6, 1.0],
                ),
                border: Border.all(
                  color: NV.brass.withValues(alpha: 0.5),
                  width: 1.4,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: data == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 22,
                            color: metal.deep.withValues(alpha: 0.8),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'ДОБАВИТЬ',
                            style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w700,
                              color: metal.deep.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ClipOval(
                      child: Image.memory(
                        data,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 7),
          Text(label.toUpperCase(), style: NV.label),
        ],
      ),
    );
  }
}
