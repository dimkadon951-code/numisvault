/// Единая точка конфигурации облака.
///
/// Вариант 1 (рекомендуется): передать значения при сборке
///   flutter build apk --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
///
/// Вариант 2: вписать значения прямо в _urlFallback / _keyFallback ниже.
///
/// Если ничего не заполнено — приложение работает полностью локально
/// (офлайн-каталог на устройстве), синхронизация просто отключается.
class AppConfig {
  const AppConfig._();

  static const String _urlEnv = String.fromEnvironment('SUPABASE_URL');
  static const String _keyEnv = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const String _urlFallback = '';
  static const String _keyFallback = '';

  static String get supabaseUrl => _urlEnv.isNotEmpty ? _urlEnv : _urlFallback;
  static String get supabaseKey => _keyEnv.isNotEmpty ? _keyEnv : _keyFallback;

  /// true, если конфигурация похожа на настоящую (URL проекта + anon key).
  static bool get hasCloudConfig =>
      supabaseUrl.startsWith('http') && supabaseKey.length > 60;

  static const String appName = 'NumisVault';
  static const String version = '1.0.0';
}
