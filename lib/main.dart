import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config.dart';
import 'data/cloud_sync.dart';
import 'data/coin_store.dart';
import 'data/local_cache.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF100907),
    ),
  );

  final supportDir = await getApplicationSupportDirectory();
  final vaultDir = Directory('${supportDir.path}/numisvault');
  if (!await vaultDir.exists()) {
    await vaultDir.create(recursive: true);
  }

  CloudSync? cloud;
  if (AppConfig.hasCloudConfig) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseKey,
      );
      cloud = CloudSync(Supabase.instance.client);
    } catch (error) {
      debugPrint('NumisVault: облако недоступно, локальный режим ($error)');
      cloud = null;
    }
  }

  final store = CoinStore(cache: LocalCache(vaultDir), cloud: cloud);
  await store.init();

  runApp(NumisVaultApp(store: store, cloud: cloud));
}
