# Получить .exe и .apk без установки инструментов

Сборка идёт на серверах GitHub (бесплатно). Вы только скачиваете готовые файлы.
Ничего устанавливать на компьютер не нужно — ни Flutter, ни Android Studio,
ни Visual Studio.

Что уже лежит в папке проекта:

* `.github/workflows/build.yml` — сборка обеих платформ по кнопке;
* `ci/build-workflow-copy.txt` — та же сборка текстом, если папку `.github`
  не удастся загрузить;
* `.gitignore` — чтобы в репозиторий не попал мусор.

---

## Вариант 1 — через Git (надёжнее, у вас Git установлен)

1. Создайте репозиторий: <https://github.com/new> → имя `numisvault` →
   тип **Private** → **Create repository**.
2. Откройте PowerShell в папке проекта и выполните по одной строке:

```powershell
cd "C:\Users\dimka\OneDrive\Документы\MultiTool\HomeChats\Chat-4\NumisVault"
git init -b main
git add .
git commit -m "NumisVault"
git remote add origin https://github.com/ВАШ_ЛОГИН/numisvault.git
git push -u origin main
```

3. На `git push` всплывёт окно входа GitHub → **Sign in with your browser** →
   подтвердите. Пароль вводить не нужно.
4. Переходите к разделу «Сборка и скачивание».

## Вариант 2 — перетаскиванием в браузере

1. Создайте репозиторий: <https://github.com/new> → `numisvault` → **Private** → **Create**.
2. На странице пустого репозитория: **uploading an existing file**.
3. В Проводнике включите показ скрытых файлов
   (Вид → Показать → Скрытые элементы), откройте папку `NumisVault`,
   выделите **всё содержимое** (Ctrl+A) и перетащите в окно браузера.
4. Нажмите **Commit changes**.
5. Проверьте, что в корне репозитория видны `pubspec.yaml`, `lib`, `.github`.
   Если `.github` нет — см. «Если папка .github не загрузилась».

---

## Сборка и скачивание

1. Вкладка **Actions**.
2. Сборка `build` стартует автоматически после коммита.
   Не стартовала — `build` → **Run workflow** → **Run workflow**.
3. Ждём 6–10 минут (две задачи: Android APK и Windows EXE, идут параллельно).
4. Внизу страницы завершённой сборки — блок **Artifacts**:

| Артефакт | Что внутри |
|---|---|
| `numisvault-windows` | ZIP: `numisvault.exe`, папка `data\`, все DLL |
| `numisvault-apk` | `app-release.apk` |

5. Скачайте оба.

### Если папка .github не загрузилась

**Actions** → **set up a workflow yourself** → удалите шаблон, вставьте текст
из `ci/build-workflow-copy.txt` (строки без `#` в начале) → **Commit changes**.
Сборка запустится сразу.

---

## Установка

**Windows.** Распакуйте ZIP в постоянную папку, например `C:\Apps\NumisVault`,
и запускайте `numisvault.exe` **из неё**. Переносить один `.exe` нельзя:
рядом должны остаться `data\`, `flutter_windows.dll` и DLL плагинов.

**Android.** Перекиньте `app-release.apk` на телефон (кабель, Telegram
«Избранное», облако) → откройте файл → разрешите «Установка неизвестных
приложений» для проводника/браузера → «Всё равно установить»
(APK подписан тестовым ключом — для личного телефона это нормально).

---

## Синхронизация между устройствами (по желанию)

Без ключей приложение работает локально: коллекция хранится на устройстве.

Чтобы включить облако:

1. Создайте проект на <https://supabase.com> (бесплатно).
2. В **SQL Editor** выполните `supabase/schema.sql` из проекта.
3. **Project Settings → API**: скопируйте `Project URL` и ключ `anon public`.
4. В GitHub: **Settings → Secrets and variables → Actions → New repository secret**:
   * `SUPABASE_URL`
   * `SUPABASE_ANON_KEY`
5. В `build.yml` замените строки сборки на:

```yaml
      - run: flutter build apk --release --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}
```

```yaml
      - run: flutter build windows --release --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}
```

6. Закоммитьте изменение → новая сборка уже с синхронизацией.
   На обоих устройствах войдите одним и тем же аккаунтом.

---

## Обновления в будущем

Меняете файлы в репозитории (или просите меня) → `git push` → Actions собирает
новые файлы автоматически. Windows: распакуйте ZIP поверх старой папки.
Android: установите APK поверх (данные сохранятся).

## Ограничения бесплатного тарифа

Private-репозиторий: 2000 минут Actions в месяц. Одна сборка — около 8 минут,
то есть ~250 сборок в месяц бесплатно. Public-репозиторий — без лимита.
