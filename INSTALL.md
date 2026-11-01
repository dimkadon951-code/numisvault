# NumisVault — установка и сборка

Пошаговая инструкция: от пустого компьютера до `.exe` на Windows и `.apk` на Android
с общей облачной коллекцией.

---

## 0. Что понадобится

| Для чего | Что установить |
|---|---|
| Общая основа (обязательно) | Flutter SDK 3.27+, Git |
| Сборка `.exe` (Windows) | Visual Studio 2022 с рабочей нагрузкой **«Разработка приложений для классического рабочего стола на C++»** |
| Сборка `.apk` (Android) | Android Studio + Android SDK 34/35, JDK 17 (ставится вместе с Android Studio) |
| Облако и синхронизация | Аккаунт Supabase (бесплатного тарифа достаточно) |

Проверка готовности окружения:

```powershell
flutter --version
flutter doctor -v
```

В выводе `flutter doctor` должны быть зелёные галочки:
`Flutter`, `Android toolchain`, `Visual Studio`, `Android Studio`/`Devices`.

Если `flutter` не найден — добавьте `C:\src\flutter\bin` в `PATH`
(переменные среды → Path → изменить → создать).

---

## 1. Развернуть проект

1. Скопируйте папку `NumisVault` в удобное место без кириллицы в пути,
   например `C:\dev\NumisVault` (кириллица в пути ломает часть нативных сборок).
2. Откройте PowerShell в этой папке:

```powershell
cd C:\dev\NumisVault
```

3. Сгенерируйте нативные оболочки (папки `android`, `windows` и т.д.) —
   в репозитории их нет, они создаются командой:

```powershell
flutter create --project-name numisvault --org com.numisvault --platforms=windows,android .
```

`--project-name` обязателен: имя папки кириллицей недопустимо как имя Dart-пакета.

4. Скачайте зависимости:

```powershell
flutter pub get
```

5. Проверьте, что всё компилируется:

```powershell
flutter analyze
```

> Папки `android/` и `windows/` создаются один раз. Повторный `flutter create` их перезапишет.

---

## 2. Разрешения Android (обязательно)

Откройте `android/app/src/main/AndroidManifest.xml` и добавьте **до** тега `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Без этой строки release-сборка не сможет подключиться к Supabase
(в debug-сборке разрешение подставляется автоматически, поэтому проблема
проявляется только в `.apk`).

Разрешение на камеру **не нужно**: съёмка идёт через системное приложение
камеры (image_picker использует intent), файлы — через системный пикер.
В `flutter doctor` ничего дополнительно настраивать не надо.

Если хотите зафиксировать портретную ориентацию (по желанию), в том же
`<activity ...>` добавьте:

```xml
android:screenOrientation="portrait"
```

---

## 3. Облако Supabase (синхронизация ПК ↔ телефон)

### 3.1. Создать проект

1. Зайдите на <https://supabase.com> → **Start your project** → войдите через GitHub.
2. **New project**: имя `numisvault`, регион ближайший к вам, пароль БД сохраните.
3. Дождитесь окончания инициализации (~2 минуты).

### 3.2. Создать таблицы

1. В левом меню: **SQL Editor** → **New query**.
2. Вставьте целиком содержимое файла `supabase/schema.sql` из проекта.
3. **Run**. Должно появиться `Success. No rows returned`.

Что создаётся: таблица `coins`, таблица `coin_images` (PNG сторон),
политики Row Level Security «только свои данные» и публикация Realtime
для мгновенной синхронизации.

> Если строка `alter publication supabase_realtime add table public.coins;`
> выдала ошибку `already member of publication` — всё в порядке, таблица уже подключена.

### 3.3. Проверить вход по e-mail

**Authentication → Providers → Email**: провайдер включён.
Для быстрых тестов удобно выключить **Confirm email**
(**Authentication → Sign In / Providers → Email → Confirm email = off**),
иначе после регистрации нужно подтверждать почту.

### 3.4. Взять ключи

**Project Settings → API**:

* `Project URL` — вида `https://abcdefgh.supabase.co`
* `anon public` ключ — длинная строка `eyJhbGciOi...`

Два способа передать их приложению.

**Способ А (рекомендуется, ничего не правим в коде):**

```powershell
flutter run -d windows --dart-define=SUPABASE_URL=https://abcdefgh.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
```

**Способ Б:** открыть `lib/config.dart` и вписать значения в
`_urlFallback` и `_keyFallback`.

Если ключи не заданы — приложение полностью работоспособно в локальном
режиме (данные только на устройстве), на экране входа есть кнопка
«Продолжить без облака».

---

## 4. Запуск и проверка

```powershell
# Windows
flutter run -d windows --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...

# Android (телефон подключён по USB, включена отладка по USB)
flutter devices
flutter run -d <id_устройства> --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

Проверка синхронизации:

1. Зарегистрируйте **один и тот же** аккаунт на ПК и на телефоне.
2. Добавьте монету на ПК → в течение 1–2 секунд она появляется на телефоне.
3. Включите на телефоне авиарежим, добавьте монету → она видна локально,
   в шапке горит «1 В ОЧЕРЕДИ». Выключите авиарежим → уходит в облако сама.

---

## 5. Сборка `.exe` для Windows

### 5.1. Собрать

```powershell
flutter build windows --release --dart-define=SUPABASE_URL=https://abcdefgh.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
```

Результат: `build\windows\x64\runner\Release\`.

### 5.2. Запустить

Внутри папки `Release` лежит `numisvault.exe`. **Запускать нужно именно из этой
папки** — рядом должны остаться `data\`, `flutter_windows.dll` и DLL плагинов.

### 5.3. Сделать «переносимую» сборку или установщик

**Портативный вариант (проще всего):** отправьте папку `Release` целиком
(или заархивируйте в ZIP). На другом ПК распакуйте и запустите `numisvault.exe`.

**Установщик `.exe` (Inno Setup, 10 минут):**

1. Установите [Inno Setup](https://jrsoftware.org/isinfo.php).
2. `File → New → Create a new script` → имя `NumisVault`, файл `numisvault.exe`,
   папка — `build\windows\x64\runner\Release`.
3. Добавьте в `[Files]` всю папку Release:

```ini
[Files]
Source: "C:\dev\NumisVault\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs
```

4. `Build → Compile` → получите `NumisVaultSetup.exe`.

Опционально: `msix`-пакет для установки из Проводника —

```powershell
dart pub global activate msix
msix create --install-certificate false
```

---

## 6. Сборка `.apk` для Android

### 6.1. Собрать без подписи (быстрая проверка)

```powershell
flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

Файл: `build\app\outputs\flutter-apk\app-release.apk`.
Такая сборка подписана debug-ключом — установить можно, но Play Protect
может предупредить, а обновлять приложение поверх придётся тем же ключом.

### 6.2. Правильная подпись (рекомендуется)

1. Создайте ключ (JDK из Android Studio, путь `keytool.exe`):

```powershell
keytool -genkey -v -keystore C:\dev\numisvault-upload.jks `
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Пароли сохраните — без них обновления невозможны.

2. Создайте файл `android/key.properties`:

```properties
storePassword=ВАШ_ПАРОЛЬ_ХРАНИЛИЩА
keyPassword=ВАШ_ПАРОЛЬ_КЛЮЧА
keyAlias=upload
storeFile=C:/dev/numisvault-upload.jks
```

3. В `android/app/build.gradle.kts` (Flutter 3.29+; если у вас `build.gradle` —
   синтаксис Groovy, см. примечание ниже) добавьте **перед** `android {`:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

и внутри `android { ... }`:

```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = keystoreProperties["storeFile"]?.let { file(it) }
        storePassword = keystoreProperties["storePassword"] as String
    }
}
buildTypes {
    getByName("release") {
        signingConfig = signingConfigs.getByName("release")
    }
}
```

<details>
<summary>Если проект сгенерирован со старым <code>build.gradle</code> (Groovy)</summary>

```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```
</details>

4. Соберите универсальный APK:

```powershell
flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

Или компактные APK под каждую архитектуру (в 2–3 раза меньше):

```powershell
flutter build apk --release --split-per-abi --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

Файлы: `build\app\outputs\flutter-apk\app-arm64-v8a-release.apk` (почти все
современные телефоны), `app-armeabi-v7a-release.apk` (старые), `app-x86_64-release.apk` (эмулятор).

Формат `.aab` для Google Play (если понадобится):

```powershell
flutter build appbundle --release --dart-define=...
```

### 6.3. Установить APK на телефон

**Вариант 1 — по кабелю (быстро):**

```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

**Вариант 2 — вручную:**

1. Скопируйте `.apk` на телефон (кабель, Telegram «Избранное», облако).
2. Откройте файл в проводнике телефона.
3. Android спросит разрешение **«Устанавливать неизвестные приложения»** →
   разрешите для проводника/браузера.
4. Play Protect может предупредить («приложение не проверено») → **Всё равно установить**.
5. Запустите NumisVault, войдите тем же аккаунтом, что и на ПК.

---

## 7. Частые проблемы

| Симптом | Причина и решение |
|---|---|
| `flutter doctor`: Visual Studio не найден | Установите Visual Studio 2022 с workload «C++ desktop»; перезапустите терминал |
| `Building with plugins requires symlink support` (Windows) | Включите режим разработчика: `start ms-settings:developers` |
| `Gradle task assembleRelease failed` с `Execution failed for task ':app:...'` | `flutter clean`, затем `flutter pub get`; проверьте JDK 17 (`flutter doctor -v`) |
| В приложении «ЛОКАЛЬНО», хотя ключи заданы | Ключи не дошли до сборки: проверьте `--dart-define` при **каждой** сборке или впишите их в `lib/config.dart` |
| Монеты не синхронизируются между устройствами | Разные аккаунты, либо в `schema.sql` не выполнены политики RLS/публикация Realtime |
| На телефоне нет фото с камеры | Проверьте, что съёмка разрешена приложению «Камера», и что APK не собран с `--dart-define` без ключей |
| `Кракозябры` в путях при сборке | Путь к проекту и к Flutter SDK не должен содержать кириллицу |
| `SupabaseException: Invalid API key` | Скопирован `service_role` вместо `anon public` — используйте только anon |
| Приложение падает при старте на Android | Проверьте `minSdk`: в `android/app/build.gradle.kts` должно быть `minSdk = 23` или выше |

---

## 8. Обновление приложения

1. `flutter clean`
2. `flutter pub get`
3. Повторите сборку из разделов 5 или 6 (ключи `--dart-define` те же).
4. Windows: замените папку `Release`. Android: `adb install -r ...apk`
   (подпись тем же ключом — данные и настройки сохранятся).
