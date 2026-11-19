
[English](https://github.com/nizar2004/onlinefix-linux/blob/main/README.md) | [Русский](https://github.com/nizar2004/onlinefix-linux/blob/main/README_ru.md)

![Окно OFME](https://zzedovec.github.io/images/ofmeBanner.png)

# OnlineFix Linux Launcher
**Простой и удобный лаунчер для запуска игр с пользовательскими исправлениями мультиплеера Linux**

> **О форке**
> Этот репозиторий — community-форк [ZzEdovec/onlinefix-linux](https://github.com/ZzEdovec/onlinefix-linux) с акцентом на **UI/UX**.
> Добавлены единая тёмная тема, полноценный экран пустого состояния с кнопкой действия, понятная боковая панель выбранной игры, улучшенные карточки и диалоги, горячая клавиша **Ctrl+O** и английский запасной перевод для отсутствующих строк.
> Всё авторство исходного приложения принадлежит его автору.

## ✨ Возможности
- Запуск игр без необходимости вручную настраивать `WINEDLLOVERRIDES` и другие параметры
- Автоматическое получение обложек игр из Steam
- Оверлей Steam
- Автоматическая установка игр с OnlineFix и FreeTP
- Специфичные патчи для некоторых типов фиксов
- Автоматическое извлечение иконок из игр
- Создание ярлыков на рабочем столе и в меню приложений для игр
- Скачивание игр из лаунчера (нужна установленная `aria2` и источник OnlineFix от Hydra Launcher)

## ❕ Совместимость
- SteamFix
    - OnlineFix - полная поддержка 64-битных, 32-битные могут иметь проблемы
    - FreeTP - только фиксы старее 2026 года
- Кастомные сервера OnlineFix (Photon Launcher)
    - Полная поддержка
- SteamFix и EOSFix (совмещенные)
    - OnlineFix - полная поддержка
    - FreeTP - полностью сломано
- EOSFix
    - OnlineFix - с EOSAuthHooker, старый тип не тестировался
    - FreeTP - полностью сломано

## 📦 Зависимости
Перед использованием лаунчера убедитесь, что установлены следующие пакеты:
- `ffmpeg`
- `steam`
- `icoextract` (необязательно) - для лучшего извлечения иконок из .exe
- `aria2` (необязательно) - для скачивания игр
- среда выполнения **Java 8** - лаунчер является JavaFX 8 приложением (`java-8-openjdk`, `jre8`, …)

‼️ Они должны быть установлены как нормальные пакеты. Flatpak и Snap версии **не поддерживаются и не будут!** В случае их использования лаунчер не будет правильно работать - и это не вина его разработчика.

## ⬇️ Установка

### 🚀 Установщик в один скрипт (рекомендуется)

В репозитории есть установщик, который сам создаёт команду запуска, ярлык в меню приложений и иконку:

```bash
git clone https://github.com/nizar2004/onlinefix-linux.git
cd onlinefix-linux
./install.sh
```

Без клонирования:

```bash
curl -fsSL https://raw.githubusercontent.com/nizar2004/onlinefix-linux/main/install.sh | bash
```

Установщик ищет JAR-файл лаунчера (`OFMELauncher.jar`) в таком порядке:
1. `--jar FILE` / `--url URL` (или переменная окружения `OFME_JAR`),
2. локальная сборка - `./OFMELauncher.jar`, `./build/OFMELauncher.jar` или `./dist/OFMELauncher.jar`,
3. последний `*.jar` из релизов GitHub (`--repo OWNER/REPO`, `--tag TAG`).

Если вы только что собрали проект в DevelNext, укажите установщику путь к сборке:

```bash
./install.sh --jar /path/to/OFMELauncher.jar
```

Чтобы установить готовую сборку upstream вместо релиза этого форка:

```bash
./install.sh --repo ZzEdovec/onlinefix-linux
```

> **Примечание**
> Этот форк пока не публикует готовых сборок. Поэтому установщику нужна либо локальная сборка из DevelNext (`--jar`), либо явный `--repo` с опубликованными релизами (например, upstream-проект выше).
> Как только здесь появится релиз с ассетом `OFMELauncher.jar`, `./install.sh` заработает без дополнительных аргументов.

#### Опции установщика

| Опция | Описание |
|---|---|
| `--jar FILE` | Установить локальный `OFMELauncher.jar` вместо загрузки |
| `--url URL` | Скачать JAR напрямую по ссылке |
| `--repo OWNER/REPO` | GitHub-репозиторий с релизом (по умолчанию `nizar2004/onlinefix-linux`) |
| `--tag TAG` | Использовать конкретный тег релиза вместо последнего |
| `--system` | Системная установка в `/opt` (при необходимости используется `sudo`) |
| `--prefix DIR` | Установка в свой префикс (`DIR/opt`, `DIR/bin`, `DIR/share`) |
| `--skip-deps` | Не проверять наличие `ffmpeg` / `steam` / дополнительных утилит |
| `-y`, `--yes` | Не задавать вопросов |

#### Куда устанавливается

| | Пользовательская установка (по умолчанию) | Системная установка (`--system`) |
|---|---|---|
| Файлы приложения | `~/.local/share/onlinefix-linux/` | `/opt/onlinefix-linux/` |
| Команда запуска | `~/.local/bin/onlinefix-linux-launcher` | `/usr/local/bin/onlinefix-linux-launcher` |
| Ярлык | `~/.local/share/applications/onlinefix-linux-launcher.desktop` | `/usr/share/applications/onlinefix-linux-launcher.desktop` |
| Иконка | `~/.local/share/icons/hicolor/128x128/apps/onlinefix-linux-launcher.png` | `/usr/share/icons/hicolor/128x128/apps/onlinefix-linux-launcher.png` |

Запуск из меню приложений или из терминала:

```bash
onlinefix-linux-launcher
```

### 🐧 Arch Linux (AUR)

Пакет upstream [onlinefix-linux-launcher-bin](https://aur.archlinux.org/packages/onlinefix-linux-launcher-bin) по-прежнему доступен (например `yay -S onlinefix-linux-launcher-bin`). Он ставит сборку upstream, без UI/UX-улучшений этого форка.

## 🗑️ Удаление

Деинсталлятор читает манифест, созданный `install.sh`, и удаляет команду запуска, ярлык, иконку и файлы приложения:

```bash
./uninstall.sh             # пользовательская установка (по умолчанию)
./uninstall.sh --system    # системная установка
./uninstall.sh --purge     # также удалить ~/.config/OFME-Linux (список игр, обложки, иконки)
```

Без клонирования:

```bash
curl -fsSL https://raw.githubusercontent.com/nizar2004/onlinefix-linux/main/uninstall.sh | bash -s -- --yes
```

#### Опции деинсталлятора

| Опция | Описание |
|---|---|
| `--system` | Удалить системную установку из `/opt` |
| `--prefix DIR` | Удалить установку, созданную через `install.sh --prefix DIR` |
| `--purge` | Также удалить пользовательские данные в `~/.config/OFME-Linux` |
| `--force` | Продолжить, даже если лаунчер ещё запущен |
| `--dry-run` | Показать, что будет удалено, ничего не меняя |
| `-y`, `--yes` | Не задавать вопросов |

Установленные игры, префиксы Proton и ярлыки отдельных игр **не удаляются** - удаляется только сам лаунчер.

## 🏗 Сборка из исходного кода
Для сборки лаунчера вам понадобится [DevelNext](https://develnext.org):
1. Откройте DevelNext
2. Клонируйте репозиторий в любую папку на вашем диске:
```bash
git clone https://github.com/nizar2004/onlinefix-linux
```
3. Откройте файл `.dnproject` в DevelNext
4. Покажется сообщение об отсутствующих зависимостях, установите их во вкладке `Проект > Пакеты`:
	- [jphp-animatefx-ext](https://github.com/jphp-group/jphp-animatefx-ext/releases)
	- [jphp-controlsfx-ext](https://github.com/jphp-group/jphp-controlsfx-ext/releases)
	- [jphp-vdf-ext](https://github.com/GIGNIGHT/jphp-vdf-ext) (требуется ручная компиляция в `dnbundle` через [jppm](https://github.com/jphp-group/jphp/releases))
	- [jphp-websocket-client](https://github.com/jphp-group/jphp-websocket-client/releases)
5. Нажмите кнопку сборки в верхней части окна

После сборки вы получите исполняемый файл лаунчера, который можно установить так:

```bash
./install.sh --jar /path/to/OFMELauncher.jar
```

## 📄 Лицензия
[GNU AGPL v3](LICENSE) - исходный проект и этот форк распространяются по лицензии AGPL-3.0.
