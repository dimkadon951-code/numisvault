import 'package:flutter/material.dart';

import '../data/coin_store.dart';
import '../models/coin.dart';
import '../models/metal.dart';
import '../theme/app_theme.dart';
import '../widgets/appear.dart';
import '../widgets/coin_card.dart';
import '../widgets/ui_kit.dart';
import '../widgets/velvet.dart';
import 'coin_detail_screen.dart';
import 'edit_coin_screen.dart';

/// Главный экран — витрина коллекции.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store, this.onSignOut});

  final CoinStore store;
  final VoidCallback? onSignOut;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _SortMode { updated, yearDesc, yearAsc, title }

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _search = TextEditingController();
  MetalType? _metal;
  String? _country;
  int? _year;
  Grade? _grade;
  _SortMode _sort = _SortMode.updated;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _signature =>
      '${_search.text}|${_metal?.name}|$_country|$_year|${_grade?.name}|${_sort.name}';

  List<Coin> _filtered(List<Coin> source) {
    final result = source.where((coin) {
      if (!coin.matches(_search.text)) return false;
      if (_metal != null && coin.metal != _metal) return false;
      if (_country != null && coin.country.trim() != _country) return false;
      if (_year != null && coin.year != _year) return false;
      if (_grade != null && coin.grade != _grade) return false;
      return true;
    }).toList();

    switch (_sort) {
      case _SortMode.updated:
        result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case _SortMode.yearDesc:
        result.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
      case _SortMode.yearAsc:
        result.sort((a, b) => (a.year ?? 9999).compareTo(b.year ?? 9999));
      case _SortMode.title:
        result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }
    return result;
  }

  bool get _hasFilters =>
      _metal != null || _country != null || _year != null || _grade != null;

  void _resetFilters() {
    setState(() {
      _metal = null;
      _country = null;
      _year = null;
      _grade = null;
      _search.clear();
    });
  }

  Future<void> _openCoin(Coin coin) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CoinDetailScreen(store: widget.store, coinId: coin.id),
      ),
    );
  }

  Future<void> _addCoin() async {
    await EditCoinScreen.open(context, widget.store);
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
              final store = widget.store;
              final coins = _filtered(store.coins);
              return Column(
                children: <Widget>[
                  _header(store),
                  _searchRow(store),
                  _filters(store),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1240),
                        child: VelvetDrawerTransition(
                          child: KeyedSubtree(
                            key: ValueKey<String>(_signature),
                            child: coins.isEmpty
                                ? _emptyState(store.coins.isEmpty)
                                : _grid(coins, store),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ шапка

  Widget _header(CoinStore store) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: NV.brassGradient,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: NV.brass.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.workspace_premium,
              size: 20,
              color: Color(0xFF2A1D05),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'NUMISVAULT',
                  style: TextStyle(
                    color: NV.parchment,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${store.coins.length} монет в собрании',
                  style: const TextStyle(color: NV.textDim, fontSize: 11.5),
                ),
              ],
            ),
          ),
          _statusPill(store),
          const SizedBox(width: 8),
          if (widget.onSignOut != null)
            BrassIconButton(
              icon: Icons.logout,
              tooltip: 'Выйти из аккаунта',
              size: 38,
              onTap: widget.onSignOut,
            ),
        ],
      ),
    );
  }

  Widget _statusPill(CoinStore store) {
    final synced = store.isCloudEnabled && store.isSignedIn && store.pendingCount == 0;
    final color = synced
        ? const Color(0xFF7BC9A3)
        : (store.isCloudEnabled ? NV.brassLight : NV.textDim);
    final text = !store.isCloudEnabled
        ? 'ЛОКАЛЬНО'
        : (store.pendingCount > 0 ? '${store.pendingCount} В ОЧЕРЕДИ' : 'СИНХРО');
    return GestureDetector(
      onTap: () => store.syncNow(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (store.syncing)
              SizedBox(
                width: 9,
                height: 9,
                child: CircularProgressIndicator(strokeWidth: 1.4, color: color),
              )
            else
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6),
                  ],
                ),
              ),
            const SizedBox(width: 7),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 9.5,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ поиск

  Widget _searchRow(CoinStore store) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NV.brass.withValues(alpha: 0.3)),
              ),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                cursorColor: NV.brassLight,
                style: const TextStyle(color: NV.parchment, fontSize: 14.5),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Поиск: страна, год, металл, легенда…',
                  hintStyle: TextStyle(
                    color: NV.textDim.withValues(alpha: 0.65),
                    fontSize: 13.5,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: NV.brass,
                  ),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : GestureDetector(
                          onTap: () {
                            _search.clear();
                            setState(() {});
                          },
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: NV.textDim,
                          ),
                        ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          BrassIconButton(
            icon: Icons.tune,
            tooltip: 'Дополнительные фильтры',
            onTap: () => _openAdvanced(store),
          ),
        ],
      ),
    );
  }

  void _openAdvanced(CoinStore store) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Widget wrap(VoidCallback update, Widget child) {
            return GestureDetector(
              onTap: () {
                update();
                setSheetState(() {});
                setState(() {});
              },
              child: child,
            );
          }

          return Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
            decoration: NV.woodPanel(radius: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text('ФИЛЬТРЫ И СОРТИРОВКА', style: NV.label),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(sheetContext).pop(),
                      child: const Icon(Icons.close, size: 18, color: NV.textDim),
                    ),
                  ],
                ),
                const BrassDivider(),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      wrap(
                        () => _metal = null,
                        NVFilterChip(
                          label: 'Любой металл',
                          selected: _metal == null,
                        ),
                      ),
                      for (final metal in MetalType.values) ...<Widget>[
                        const SizedBox(width: 8),
                        wrap(
                          () => _metal = metal,
                          NVFilterChip(
                            label: metal.label,
                            selected: _metal == metal,
                            dotColor: metal.base,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: NVDropdown<String>(
                        label: 'Страна',
                        value: _country,
                        hint: 'Все страны',
                        items: store.countries,
                        itemLabel: (v) => v,
                        onChanged: (value) => setState(() => _country = value),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: NVDropdown<int>(
                        label: 'Год',
                        value: _year,
                        hint: 'Все годы',
                        items: store.years,
                        itemLabel: (v) => '$v',
                        onChanged: (value) => setState(() => _year = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: NVDropdown<Grade>(
                        label: 'Сохранность',
                        value: _grade,
                        hint: 'Любая',
                        items: Grade.values,
                        itemLabel: (g) => '${g.short} · ${g.ru}',
                        onChanged: (value) => setState(() => _grade = value),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: NVDropdown<_SortMode>(
                        label: 'Сортировка',
                        value: _sort,
                        items: _SortMode.values,
                        itemLabel: (mode) {
                          switch (mode) {
                            case _SortMode.updated:
                              return 'По дате изменения';
                            case _SortMode.yearDesc:
                              return 'Год: новые';
                            case _SortMode.yearAsc:
                              return 'Год: старые';
                            case _SortMode.title:
                              return 'По названию';
                          }
                        },
                        onChanged: (value) => setState(() => _sort = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: BrassButton(
                        label: 'Сбросить',
                        dark: true,
                        dense: true,
                        expand: true,
                        onTap: () {
                          _resetFilters();
                          setSheetState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: BrassButton(
                        label: 'Показать',
                        dense: true,
                        expand: true,
                        onTap: () => Navigator.of(sheetContext).pop(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------------ чипы

  Widget _filters(CoinStore store) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: <Widget>[
          NVFilterChip(
            label: 'Все',
            selected: _metal == null,
            onTap: () => setState(() => _metal = null),
          ),
          for (final metal in MetalType.values) ...<Widget>[
            const SizedBox(width: 8),
            NVFilterChip(
              label: metal.label,
              selected: _metal == metal,
              dotColor: metal.base,
              onTap: () => setState(() {
                _metal = _metal == metal ? null : metal;
              }),
            ),
          ],
          if (_hasFilters) ...<Widget>[
            const SizedBox(width: 10),
            NVFilterChip(
              label: 'Сбросить',
              selected: false,
              onTap: _resetFilters,
            ),
          ],
          const SizedBox(width: 60),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ сетка

  Widget _grid(List<Coin> coins, CoinStore store) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width < 520
            ? 2
            : width < 800
                ? 3
                : width < 1100
                    ? 4
                    : 5;
        final spacing = width < 520 ? 10.0 : 16.0;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 0.64,
          ),
          itemCount: coins.length,
          itemBuilder: (context, index) {
            final coin = coins[index];
            return Appear(
              index: index > 12 ? 12 : index,
              child: CoinCard(
                coin: coin,
                obverse: store.image(coin.id, CoinFace.obverse),
                onTap: () => _openCoin(coin),
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyState(bool collectionEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: NV.brassGradient,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: NV.brass.withValues(alpha: 0.25),
                    blurRadius: 26,
                  ),
                ],
              ),
              child: const Icon(
                Icons.workspace_premium,
                size: 44,
                color: Color(0xFF2A1D05),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              collectionEmpty
                  ? 'Витрина пока пуста'
                  : 'Ничего не найдено',
              style: NV.serifTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              collectionEmpty
                  ? 'Добавьте первую монету: фото аверса и реверса,\nметалл, монетный двор и историю.'
                  : 'Попробуйте изменить фильтры или поисковый запрос.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: NV.textDim.withValues(alpha: 0.9),
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            BrassButton(
              label: collectionEmpty ? 'Добавить монету' : 'Сбросить фильтры',
              icon: collectionEmpty ? Icons.add : Icons.refresh,
              onTap: collectionEmpty ? _addCoin : _resetFilters,
            ),
          ],
        ),
      ),
    );
  }
}
