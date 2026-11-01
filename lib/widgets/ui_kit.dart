import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'velvet.dart';

/// Кнопка из латуни с полированным градиентом и «вдавливанием» при нажатии.
class BrassButton extends StatefulWidget {
  const BrassButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.expand = false,
    this.dense = false,
    this.dark = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool expand;
  final bool dense;

  /// Тёмный вариант (бархатная кнопка с латунной рамкой).
  final bool dark;

  @override
  State<BrassButton> createState() => _BrassButtonState();
}

class _BrassButtonState extends State<BrassButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final child = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (widget.icon != null) ...<Widget>[
          Icon(
            widget.icon,
            size: widget.dense ? 15 : 18,
            color: widget.dark ? NV.brassLight : const Color(0xFF2A1D05),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: widget.dark ? NV.brassLight : const Color(0xFF2A1D05),
              fontSize: widget.dense ? 12 : 14,
              fontWeight: FontWeight.w700,
              letterSpacing: widget.dense ? 1.1 : 1.6,
            ),
          ),
        ),
      ],
    );

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: AnimatedScale(
        scale: _down ? 0.965 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapCancel: enabled ? () => setState(() => _down = false) : null,
          onTapUp: enabled
              ? (_) {
                  setState(() => _down = false);
                  widget.onTap?.call();
                }
              : null,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.dense ? 14 : 22,
              vertical: widget.dense ? 9 : 14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.dense ? 10 : 14),
              gradient: widget.dark ? null : NV.brassGradient,
              color: widget.dark ? const Color(0xFF2A1710) : null,
              border: Border.all(
                color: widget.dark
                    ? NV.brass.withValues(alpha: 0.55)
                    : NV.brassDark.withValues(alpha: 0.7),
                width: 1.1,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: widget.dark ? 0.4 : 0.5),
                  blurRadius: widget.dense ? 6 : 12,
                  offset: Offset(0, widget.dense ? 3 : 6),
                ),
                if (!widget.dark)
                  BoxShadow(
                    color: NV.brassLight.withValues(alpha: 0.25),
                    blurRadius: 2,
                    offset: const Offset(0, -1),
                  ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Круглый латунный переключатель-иконка.
class BrassIconButton extends StatelessWidget {
  const BrassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.tooltip,
    this.size = 42,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF2A1710),
          border: Border.all(color: NV.brass.withValues(alpha: 0.45), width: 1.1),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: size * 0.46, color: color ?? NV.brassLight),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Поле ввода «под латунной гравировкой».
class NVField extends StatelessWidget {
  const NVField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
    this.textCapitalization = TextCapitalization.sentences,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label.toUpperCase(), style: NV.label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          textCapitalization: textCapitalization,
          cursorColor: NV.brassLight,
          style: const TextStyle(color: NV.parchment, fontSize: 15),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(
              color: NV.textDim.withValues(alpha: 0.6),
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.28),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: NV.brass.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: NV.brass, width: 1.4),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: NV.burgundy.withValues(alpha: 0.9)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFB4475C), width: 1.4),
            ),
            errorStyle: const TextStyle(color: Color(0xFFE08A9A), fontSize: 12),
          ),
        ),
      ],
    );
  }
}

/// Кастомный «барабанный» выпадающий список — без Material-меню,
/// чтобы не выбиваться из стиля.
class NVDropdown<T> extends StatelessWidget {
  const NVDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.hint = 'Не выбрано',
    this.icon,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final ValueChanged<T> onChanged;
  final String hint;
  final IconData? icon;

  Future<void> _open(BuildContext context) async {
    final selected = await showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.62,
          ),
          margin: const EdgeInsets.all(12),
          decoration: NV.woodPanel(radius: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Text(label.toUpperCase(), style: NV.label)),
                    GestureDetector(
                      onTap: () => Navigator.of(sheetContext).pop(),
                      child: const Icon(Icons.close, size: 18, color: NV.textDim),
                    ),
                  ],
                ),
              ),
              const BrassDivider(indent: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final active = item == value;
                    return InkWell(
                      onTap: () => Navigator.of(sheetContext).pop(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                        color: active
                            ? NV.brass.withValues(alpha: 0.12)
                            : Colors.transparent,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                itemLabel(item),
                                style: TextStyle(
                                  color: active ? NV.brassLight : NV.text,
                                  fontSize: 15,
                                  fontWeight:
                                      active ? FontWeight.w700 : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (active)
                              const Icon(Icons.check, size: 16, color: NV.brassLight),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label.toUpperCase(), style: NV.label),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _open(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: NV.brass.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 15, color: NV.brass.withValues(alpha: 0.8)),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    value == null ? hint : itemLabel(value as T),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: value == null ? NV.textDim : NV.parchment,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Icon(Icons.expand_more, size: 18, color: NV.brass),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Чип-фильтр.
class NVFilterChip extends StatelessWidget {
  const NVFilterChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.dotColor,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: selected ? NV.brassGradient : null,
          color: selected ? null : Colors.black.withValues(alpha: 0.3),
          border: Border.all(
            color: selected
                ? NV.brassDark.withValues(alpha: 0.8)
                : NV.brass.withValues(alpha: 0.25),
          ),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: NV.brass.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (dotColor != null) ...<Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: dotColor!.withValues(alpha: 0.6), blurRadius: 4),
                  ],
                ),
              ),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.5,
                color: selected ? const Color(0xFF2A1D05) : NV.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Заголовок секции: гравированная надпись + латунные линии по бокам.
class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.text, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            text.toUpperCase(),
            style: NV.label.copyWith(fontSize: 11.5, letterSpacing: 2.2),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Строка характеристики: подпись слева, значение справа.
class SpecRow extends StatelessWidget {
  const SpecRow({
    super.key,
    required this.label,
    required this.value,
    this.monospace = false,
  });

  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: NV.textDim,
                fontSize: 12.5,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: NV.parchment,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFeatures: monospace ? const <FontFeature>[FontFeature.tabularFigures()] : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
