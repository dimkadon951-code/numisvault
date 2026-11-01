import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/coin.dart';

/// Тонкая обёртка над Supabase: авторизация, realtime-поток монет,
/// загрузка/скачивание PNG сторон.
///
/// Схема БД — см. `supabase/schema.sql`.
class CloudSync {
  CloudSync(this.client);

  final SupabaseClient client;

  String? get userId => client.auth.currentUser?.id;
  bool get isSignedIn => client.auth.currentUser != null;

  Stream<AuthState> get authChanges => client.auth.onAuthStateChange;

  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(email: email.trim(), password: password);
  }

  /// Возвращает true, если сессия создана сразу.
  /// false — если включено подтверждение e-mail.
  Future<bool> signUp(String email, String password) async {
    final res = await client.auth.signUp(
      email: email.trim(),
      password: password,
    );
    return res.session != null;
  }

  Future<void> signOut() => client.auth.signOut();

  Stream<List<Coin>> watchCoins() {
    final uid = userId;
    if (uid == null) return const Stream<List<Coin>>.empty();
    return client
        .from('coins')
        .stream(primaryKey: <String>['id'])
        .eq('user_id', uid)
        .map((rows) => rows
            .map((row) => Coin.fromRow(Map<String, dynamic>.from(row)))
            .toList());
  }

  Future<void> upsertCoin(Coin coin) async {
    final uid = userId;
    if (uid == null) throw AuthException('Не выполнен вход');
    await client.from('coins').upsert(coin.toRow(uid));
  }

  Future<void> deleteCoin(String coinId) async {
    final uid = userId;
    if (uid == null) throw AuthException('Не выполнен вход');
    await client.from('coins').delete().eq('id', coinId).eq('user_id', uid);
    await client
        .from('coin_images')
        .delete()
        .eq('coin_id', coinId)
        .eq('user_id', uid);
  }

  String _imageId(String coinId, CoinFace face) => '$coinId:${face.name}';

  Future<void> uploadImage(String coinId, CoinFace face, Uint8List bytes) async {
    final uid = userId;
    if (uid == null) throw AuthException('Не выполнен вход');
    await client.from('coin_images').upsert(<String, dynamic>{
      'id': _imageId(coinId, face),
      'user_id': uid,
      'coin_id': coinId,
      'face': face.name,
      'png': base64Encode(bytes),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<Uint8List?> fetchImage(String coinId, CoinFace face) async {
    final uid = userId;
    if (uid == null) return null;
    try {
      final row = await client
          .from('coin_images')
          .select('png')
          .eq('id', _imageId(coinId, face))
          .eq('user_id', uid)
          .maybeSingle();
      if (row == null) return null;
      final encoded = row['png'] as String?;
      if (encoded == null || encoded.isEmpty) return null;
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }
}
