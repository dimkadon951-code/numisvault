import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../models/coin.dart';

/// Отложенная операция, которая не дошла до облака.
class PendingOp {
  PendingOp.upsert(Coin coin)
      : isDelete = false,
        coin = coin;

  PendingOp.delete(String coinId)
      : isDelete = true,
        coin = Coin(id: coinId, title: '', updatedAt: DateTime.now());

  final bool isDelete;
  final Coin coin;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'op': isDelete ? 'delete' : 'upsert',
        'coin': coin.toJson(),
      };

  factory PendingOp.fromJson(Map<String, dynamic> json) {
    final type = json['op'] as String? ?? 'upsert';
    final coin = Coin.fromJson(Map<String, dynamic>.from(json['coin'] as Map));
    return type == 'delete' ? PendingOp.delete(coin.id) : PendingOp.upsert(coin);
  }
}

/// Дисковый кэш: список монет, очередь синхронизации и PNG-файлы сторон монеты.
///
/// Файлы лежат в каталоге поддержки приложения:
///   Windows: %APPDATA%\...\numisvault
///   Android: /data/data/<пакет>/files/numisvault
class LocalCache {
  LocalCache(this.dir);

  final Directory dir;

  File get _coinsFile => File('${dir.path}/coins.json');
  File get _queueFile => File('${dir.path}/queue.json');
  Directory get _imagesDir => Directory('${dir.path}/images');

  Future<void> _ensureDirs() async {
    if (!await dir.exists()) await dir.create(recursive: true);
    if (!await _imagesDir.exists()) await _imagesDir.create(recursive: true);
  }

  String _imageName(String coinId, CoinFace face) =>
      '${coinId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}_${face.name}.png';

  File imageFile(String coinId, CoinFace face) =>
      File('${_imagesDir.path}/${_imageName(coinId, face)}');

  Future<List<Coin>> loadCoins() async {
    try {
      if (!await _coinsFile.exists()) return <Coin>[];
      final raw = await _coinsFile.readAsString();
      if (raw.trim().isEmpty) return <Coin>[];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Coin.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return <Coin>[];
    }
  }

  Future<void> saveCoins(List<Coin> coins) async {
    await _ensureDirs();
    final payload = jsonEncode(coins.map((c) => c.toJson()).toList());
    await _coinsFile.writeAsString(payload, flush: true);
  }

  Future<List<PendingOp>> loadQueue() async {
    try {
      if (!await _queueFile.exists()) return <PendingOp>[];
      final raw = await _queueFile.readAsString();
      if (raw.trim().isEmpty) return <PendingOp>[];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => PendingOp.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return <PendingOp>[];
    }
  }

  Future<void> saveQueue(List<PendingOp> queue) async {
    await _ensureDirs();
    final payload = jsonEncode(queue.map((o) => o.toJson()).toList());
    await _queueFile.writeAsString(payload, flush: true);
  }

  Future<Uint8List?> loadImage(String coinId, CoinFace face) async {
    try {
      final file = imageFile(coinId, face);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveImage(String coinId, CoinFace face, Uint8List bytes) async {
    await _ensureDirs();
    await imageFile(coinId, face).writeAsBytes(bytes, flush: true);
  }

  Future<void> deleteImages(String coinId) async {
    for (final face in CoinFace.values) {
      final file = imageFile(coinId, face);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
  }
}
