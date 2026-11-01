import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/coin.dart';
import 'cloud_sync.dart';
import 'local_cache.dart';

/// Хранилище коллекции: офлайн-first.
///
/// Схема работы:
///  1. Все данные сразу ложатся в дисковый кэш — приложение читается офлайн.
///  2. Изменение ставится в очередь (queue.json) и пытается уйти в облако.
///  3. Если сети нет — операция остаётся в очереди, статус показывается в UI.
///  4. Realtime-поток облака перезаписывает локальный список, поверх него
///     накладываются ещё не отправленные операции (локальные правки не теряются).
class CoinStore extends ChangeNotifier {
  CoinStore({required this.cache, this.cloud});

  final LocalCache cache;
  CloudSync? cloud;

  final List<Coin> _coins = <Coin>[];
  final List<PendingOp> _queue = <PendingOp>[];
  final Map<String, Uint8List> _images = <String, Uint8List>{};
  final Set<String> _loadingImages = <String>{};
  final Set<String> _missingImages = <String>{};
  final Map<String, int> _imageVersions = <String, int>{};

  StreamSubscription<List<Coin>>? _liveSub;
  Timer? _retryTimer;
  bool _localOnly = false;
  bool _syncing = false;
  String _status = 'Локальный режим';

  List<Coin> get coins => List<Coin>.unmodifiable(_coins);
  int get pendingCount => _queue.length;
  bool get isCloudEnabled => cloud != null && !_localOnly;
  bool get syncing => _syncing;
  String get status => _status;
  bool get isSignedIn => cloud?.isSignedIn ?? false;

  // ---------------------------------------------------------------- служебное

  Future<void> init() async {
    final cached = await cache.loadCoins();
    _coins
      ..clear()
      ..addAll(cached);
    _queue
      ..clear()
      ..addAll(await cache.loadQueue());
    _sort();
    notifyListeners();
    if (isSignedIn) {
      _startRealtime();
      unawaited(_flush());
    }
  }

  void setLocalOnly(bool value) {
    _localOnly = value;
    if (value) {
      unawaited(_liveSub?.cancel());
      _liveSub = null;
      _retryTimer?.cancel();
      _status = 'Локальный режим';
    } else if (isSignedIn) {
      _startRealtime();
      unawaited(_flush());
    }
    notifyListeners();
  }

  /// Вызывается после входа/выхода из аккаунта.
  Future<void> onAuthChanged() async {
    await _liveSub?.cancel();
    _liveSub = null;
    if (isSignedIn && !_localOnly) {
      _startRealtime();
      await _flush();
    } else {
      _status = 'Локальный режим';
      notifyListeners();
    }
  }

  void _startRealtime() {
    final c = cloud;
    if (c == null || !c.isSignedIn) return;
    _liveSub?.cancel();
    _status = 'Синхронизация…';
    _liveSub = c.watchCoins().listen(
      (remote) {
        final merged = _overlayPending(remote);
        _coins
          ..clear()
          ..addAll(merged);
        _sort();
        _status = _queue.isEmpty ? 'Синхронизировано' : 'В очереди: ${_queue.length}';
        notifyListeners();
        unawaited(cache.saveCoins(_coins));
        unawaited(_flush());
      },
      onError: (Object _) {
        _status = 'Офлайн · кэш';
        notifyListeners();
        _scheduleRetry();
      },
      cancelOnError: false,
    );
  }

  List<Coin> _overlayPending(List<Coin> remote) {
    final map = <String, Coin>{for (final c in remote) c.id: c};
    for (final op in _queue) {
      if (op.isDelete) {
        map.remove(op.coin.id);
      } else {
        map[op.coin.id] = op.coin;
      }
    }
    return map.values.toList();
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 12), () {
      if (isSignedIn && !_localOnly) unawaited(_flush());
    });
  }

  void _sort() {
    _coins.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  // ------------------------------------------------------------------- запись

  Future<void> save(
    Coin coin, {
    Uint8List? obverse,
    Uint8List? reverse,
  }) async {
    final updated = coin.copyWith(updatedAt: DateTime.now());

    if (obverse != null) {
      await cache.saveImage(updated.id, CoinFace.obverse, obverse);
      _putImage(updated.id, CoinFace.obverse, obverse);
    }
    if (reverse != null) {
      await cache.saveImage(updated.id, CoinFace.reverse, reverse);
      _putImage(updated.id, CoinFace.reverse, reverse);
    }

    final index = _coins.indexWhere((c) => c.id == updated.id);
    if (index >= 0) {
      _coins[index] = updated;
    } else {
      _coins.add(updated);
    }
    _sort();
    notifyListeners();
    await cache.saveCoins(_coins);

    _enqueue(PendingOp.upsert(updated));
    await _flush();
  }

  Future<void> delete(String coinId) async {
    _coins.removeWhere((c) => c.id == coinId);
    _images.removeWhere((key, _) => key.startsWith('$coinId:'));
    _imageVersions.removeWhere((key, _) => key.startsWith('$coinId:'));
    notifyListeners();
    await cache.saveCoins(_coins);
    await cache.deleteImages(coinId);

    _enqueue(PendingOp.delete(coinId));
    await _flush();
  }

  /// Убирает старую запись из очереди по тому же id и добавляет свежую.
  void _enqueue(PendingOp op) {
    _queue.removeWhere((o) => o.coin.id == op.coin.id);
    _queue.add(op);
    unawaited(cache.saveQueue(_queue));
  }

  Future<void> _flush() async {
    final c = cloud;
    if (c == null || !c.isSignedIn || _localOnly) return;
    if (_syncing) return;
    _syncing = true;
    notifyListeners();
    try {
      for (final op in List<PendingOp>.of(_queue)) {
        try {
          if (op.isDelete) {
            await c.deleteCoin(op.coin.id);
          } else {
            await c.upsertCoin(op.coin);
            for (final face in CoinFace.values) {
              final bytes = _images['${op.coin.id}:${face.name}'] ??
                  await cache.loadImage(op.coin.id, face);
              if (bytes != null) {
                await c.uploadImage(op.coin.id, face, bytes);
              }
            }
          }
          _queue.remove(op);
        } catch (_) {
          break;
        }
      }
      _status = _queue.isEmpty ? 'Синхронизировано' : 'Офлайн · ${_queue.length} в очереди';
      if (_queue.isNotEmpty) _scheduleRetry();
      await cache.saveQueue(_queue);
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  /// Ручное «синхронизировать сейчас».
  Future<void> syncNow() async {
    if (!isSignedIn) {
      _status = 'Локальный режим';
      notifyListeners();
      return;
    }
    _startRealtime();
    await _flush();
  }

  // ------------------------------------------------------------------ картинки

  String _key(String coinId, CoinFace face) => '$coinId:${face.name}';

  void _putImage(String coinId, CoinFace face, Uint8List bytes) {
    final key = _key(coinId, face);
    _images[key] = bytes;
    _missingImages.remove(key);
    _imageVersions[key] = (_imageVersions[key] ?? 0) + 1;
  }

  int imageVersion(String coinId, CoinFace face) =>
      _imageVersions[_key(coinId, face)] ?? 0;

  /// Синхронный доступ к картинке. Если её нет — запускает загрузку
  /// (диск → облако) и вернёт null до готовности; затем notifyListeners().
  Uint8List? image(String coinId, CoinFace face) {
    final key = _key(coinId, face);
    final hit = _images[key];
    if (hit != null) return hit;
    if (_missingImages.contains(key) || _loadingImages.contains(key)) return null;
    _loadingImages.add(key);
    unawaited(_loadImage(coinId, face));
    return null;
  }

  Future<void> _loadImage(String coinId, CoinFace face) async {
    final key = _key(coinId, face);
    try {
      var bytes = await cache.loadImage(coinId, face);
      if (bytes == null && cloud != null && cloud!.isSignedIn && !_localOnly) {
        bytes = await cloud!.fetchImage(coinId, face);
        if (bytes != null) await cache.saveImage(coinId, face, bytes);
      }
      if (bytes != null) {
        _putImage(coinId, face, bytes);
        notifyListeners();
      } else {
        // Запоминаем, что картинки нет, чтобы не читать диск каждый кадр.
        _missingImages.add(key);
      }
    } catch (_) {
      _missingImages.add(key);
    } finally {
      _loadingImages.remove(key);
    }
  }

  // -------------------------------------------------------------------- утиль

  /// Все страны, встречающиеся в коллекции — для фильтра.
  List<String> get countries {
    final set = <String>{};
    for (final c in _coins) {
      if (c.country.trim().isNotEmpty) set.add(c.country.trim());
    }
    final list = set.toList()..sort();
    return list;
  }

  List<int> get years {
    final set = <int>{};
    for (final c in _coins) {
      if (c.year != null) set.add(c.year!);
    }
    final list = set.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  static String newId() => const Uuid().v4();

  @override
  void dispose() {
    _retryTimer?.cancel();
    _liveSub?.cancel();
    super.dispose();
  }
}
