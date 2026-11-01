import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'data/cloud_sync.dart';
import 'data/coin_store.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

/// Корневой виджет: решает, показать витрину или экран входа.
class NumisVaultApp extends StatefulWidget {
  const NumisVaultApp({super.key, required this.store, this.cloud});

  final CoinStore store;
  final CloudSync? cloud;

  @override
  State<NumisVaultApp> createState() => _NumisVaultAppState();
}

class _NumisVaultAppState extends State<NumisVaultApp> {
  late bool _localMode = widget.cloud == null;

  @override
  void initState() {
    super.initState();
    widget.cloud?.authChanges.listen((AuthState _) async {
      final signedIn = widget.cloud?.isSignedIn ?? false;
      if (signedIn) widget.store.setLocalOnly(false);
      await widget.store.onAuthChanged();
      if (mounted) setState(() {});
    });
    if (widget.cloud?.isSignedIn ?? false) {
      widget.store.setLocalOnly(false);
    }
  }

  Future<void> _signOut() async {
    await widget.cloud?.signOut();
    if (!mounted) return;
    widget.store.setLocalOnly(true);
    setState(() => _localMode = false);
  }

  @override
  Widget build(BuildContext context) {
    final cloud = widget.cloud;
    Widget home;
    if (cloud == null) {
      home = HomeScreen(store: widget.store);
    } else if (!_localMode && !cloud.isSignedIn) {
      home = LoginScreen(
        cloud: cloud,
        onLocalMode: () {
          widget.store.setLocalOnly(true);
          setState(() => _localMode = true);
        },
      );
    } else {
      home = HomeScreen(store: widget.store, onSignOut: _signOut);
    }

    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: NV.theme(),
      home: home,
    );
  }
}
