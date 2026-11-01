import 'package:flutter/material.dart';

import '../data/cloud_sync.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';
import '../widgets/velvet.dart';

/// Вход в облако (Supabase). Один и тот же аккаунт на ПК и Android
/// даёт общую коллекцию и realtime-синхронизацию.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.cloud,
    required this.onLocalMode,
  });

  final CloudSync cloud;
  final VoidCallback onLocalMode;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Введите корректный e-mail');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Пароль не короче 6 символов');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_register) {
        final signedIn = await widget.cloud.signUp(email, password);
        if (!signedIn && mounted) {
          setState(() {
            _error =
                'Аккаунт создан. Подтвердите e-mail по ссылке из письма и войдите.';
            _register = false;
          });
        }
      } else {
        await widget.cloud.signIn(email, password);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _humanize(error.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _humanize(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid login') || lower.contains('invalid credentials')) {
      return 'Неверный e-mail или пароль';
    }
    if (lower.contains('already registered') || lower.contains('already been registered')) {
      return 'Этот e-mail уже зарегистрирован — войдите';
    }
    if (lower.contains('email not confirmed')) {
      return 'E-mail не подтверждён — проверьте почту';
    }
    if (lower.contains('socket') ||
        lower.contains('network') ||
        lower.contains('failed host lookup')) {
      return 'Нет связи с сервером. Проверьте интернет.';
    }
    return raw.replaceFirst('AuthException(message: ', '').replaceAll(')', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NV.backdrop,
      body: VaultBackground(
        burgundy: true,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: NV.brassGradient,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: NV.brass.withValues(alpha: 0.3),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.workspace_premium,
                        size: 40,
                        color: Color(0xFF2A1D05),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'NUMISVAULT',
                      style: TextStyle(
                        color: NV.parchment,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Мюнцкабинет в кармане',
                      style: TextStyle(
                        color: NV.textDim.withValues(alpha: 0.9),
                        fontSize: 12,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 26),
                    WoodPanel(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _tab('Вход', !_register),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _tab('Регистрация', _register),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          NVField(
                            label: 'E-mail',
                            hint: 'you@example.com',
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textCapitalization: TextCapitalization.none,
                          ),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text('ПАРОЛЬ', style: NV.label),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _password,
                                obscureText: _obscure,
                                cursorColor: NV.brassLight,
                                style: const TextStyle(
                                  color: NV.parchment,
                                  fontSize: 15,
                                ),
                                onSubmitted: (_) {
                                  if (!_busy) _submit();
                                },
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.black.withValues(alpha: 0.28),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  suffixIcon: GestureDetector(
                                    onTap: () =>
                                        setState(() => _obscure = !_obscure),
                                    child: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 18,
                                      color: NV.textDim,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: NV.brass.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: NV.brass,
                                      width: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_error != null) ...<Widget>[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: const TextStyle(
                                color: Color(0xFFE08A9A),
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          BrassButton(
                            label: _busy
                                ? 'Подключение…'
                                : (_register ? 'Создать аккаунт' : 'Войти'),
                            icon: Icons.lock_open,
                            expand: true,
                            onTap: _busy ? null : _submit,
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: widget.onLocalMode,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Продолжить без облака (локально)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: NV.textDim.withValues(alpha: 0.9),
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                  decorationColor: NV.textDim,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Один аккаунт — одна коллекция на ПК и телефоне.\n'
                      'Данные хранятся в вашем проекте Supabase.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: NV.textDim.withValues(alpha: 0.75),
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(String label, bool active) {
    return GestureDetector(
      onTap: () => setState(() {
        _register = label == 'Регистрация';
        _error = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: active ? NV.brassGradient : null,
          color: active ? null : Colors.black.withValues(alpha: 0.3),
          border: Border.all(
            color: active
                ? NV.brassDark.withValues(alpha: 0.8)
                : NV.brass.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? const Color(0xFF2A1D05) : NV.textDim,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}
