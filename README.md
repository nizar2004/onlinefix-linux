
[English](https://github.com/nizar2004/onlinefix-linux/blob/main/README.md) | [Русский](https://github.com/nizar2004/onlinefix-linux/blob/main/README_ru.md)

![OFME Window](https://zzedovec.github.io/images/ofmeBanner.png)

# OnlineFix Linux Launcher
**A simple and convenient launcher for running games with custom multiplayer fixes on Linux**

> **Fork notice**
> This repository is a community fork of [ZzEdovec/onlinefix-linux](https://github.com/ZzEdovec/onlinefix-linux) with a focus on **UI/UX**.
> It adds a unified dark design system, a proper empty state with a call to action, a clearer game sidebar, improved cards and dialogs, a **Ctrl+O** shortcut, and an English fallback for missing translations.
> All credit for the original application goes to its author.

## ✨ Features
- Launch games without manually configuring `WINEDLLOVERRIDES` and other parameters
- Automatically fetch game covers from Steam
- Steam overlay support
- Automatic installation of OnlineFix and FreeTP games
- Specific patches for certain types of fixes
- Automatic extraction of icons from games
- Create desktop and application menu shortcuts for games
- Download games directly from the launcher (requires `aria2` and an OnlineFix source from Hydra Launcher)

## ❕ Compatibility
- SteamFix
    - OnlineFix - full 64-bit support, 32-bit may have issues
    - FreeTP - only fixes older than 2026
- Custom OnlineFix servers (Photon Launcher)
    - Full support
- SteamFix + EOSFix (combined)
    - OnlineFix - full support
    - FreeTP - completely broken
- EOSFix
    - OnlineFix - with EOSAuthHooker, legacy mode untested
    - FreeTP - completely broken

## 📦 Dependencies
Before using the launcher, make sure the following packages are installed:
- `ffmpeg`
- `steam`
- `icoextract` (optional) – for better extraction of icons from .exe files
- `aria2` (optional) – for downloading games
- a **Java 8** runtime – the launcher is a JavaFX 8 application (`java-8-openjdk`, `jre8`, …)

‼️ These must be installed as regular packages. Flatpak and Snap versions **are not supported and will not be!** If you use them, the launcher will not work correctly – and this is not the developer's fault.

## ⬇️ Installation

### 🚀 Script installer (recommended)

The repository ships an installer that sets up the launcher command, the desktop entry and the icon for you:

```bash
git clone https://github.com/nizar2004/onlinefix-linux.git
cd onlinefix-linux
./install.sh
```

Without cloning:

```bash
curl -fsSL https://raw.githubusercontent.com/nizar2004/onlinefix-linux/main/install.sh | bash
```

The installer resolves the launcher JAR (`OFMELauncher.jar`) in this order:
1. `--jar FILE` / `--url URL` (or the `OFME_JAR` environment variable),
2. a local build – `./OFMELauncher.jar`, `./build/OFMELauncher.jar` or `./dist/OFMELauncher.jar`,
3. the newest `*.jar` asset of a GitHub release (`--repo OWNER/REPO`, `--tag TAG`).

If you have just built the project with DevelNext, point the installer at the build output:

```bash
./install.sh --jar /path/to/OFMELauncher.jar
```

To install an existing upstream build instead of a release of this fork:

```bash
./install.sh --repo ZzEdovec/onlinefix-linux
```

#### Installer options

| Option | Description |
|---|---|
| `--jar FILE` | Install a local `OFMELauncher.jar` instead of downloading one |
| `--url URL` | Download the launcher JAR from a direct URL |
| `--repo OWNER/REPO` | GitHub repository used as release source (default: `nizar2004/onlinefix-linux`) |
| `--tag TAG` | Use a specific release tag instead of the latest one |
| `--system` | Install system-wide in `/opt` (uses `sudo` when needed) |
| `--prefix DIR` | Install under a custom prefix (`DIR/opt`, `DIR/bin`, `DIR/share`) |
| `--skip-deps` | Skip the `ffmpeg` / `steam` / optional tool checks |
| `-y`, `--yes` | Do not ask for confirmation |

#### Where things are installed

| | User install (default) | System install (`--system`) |
|---|---|---|
| Application files | `~/.local/share/onlinefix-linux/` | `/opt/onlinefix-linux/` |
| Launcher command | `~/.local/bin/onlinefix-linux-launcher` | `/usr/local/bin/onlinefix-linux-launcher` |
| Desktop entry | `~/.local/share/applications/onlinefix-linux-launcher.desktop` | `/usr/share/applications/onlinefix-linux-launcher.desktop` |
| Icon | `~/.local/share/icons/hicolor/128x128/apps/onlinefix-linux-launcher.png` | `/usr/share/icons/hicolor/128x128/apps/onlinefix-linux-launcher.png` |

The launcher can be started from your application menu or from a terminal:

```bash
onlinefix-linux-launcher
```

### 🐧 Arch Linux (AUR)

The upstream package [onlinefix-linux-launcher-bin](https://aur.archlinux.org/packages/onlinefix-linux-launcher-bin) is still available (for example `yay -S onlinefix-linux-launcher-bin`). It installs the upstream build, not the UI/UX improvements of this fork.

## 🗑️ Uninstall

The uninstaller reads the manifest written by `install.sh` and removes the launcher command, desktop entry, icon and application directory:

```bash
./uninstall.sh             # user installation (default)
./uninstall.sh --system    # system-wide installation
./uninstall.sh --purge     # also delete ~/.config/OFME-Linux (game list, banners, icons)
```

Without cloning:

```bash
curl -fsSL https://raw.githubusercontent.com/nizar2004/onlinefix-linux/main/uninstall.sh | bash -s -- --yes
```

#### Uninstaller options

| Option | Description |
|---|---|
| `--system` | Remove a system-wide installation from `/opt` |
| `--prefix DIR` | Remove an installation made with `install.sh --prefix DIR` |
| `--purge` | Also delete user data in `~/.config/OFME-Linux` |
| `--force` | Continue even if the launcher is still running |
| `--dry-run` | Show what would be removed without changing anything |
| `-y`, `--yes` | Do not ask for confirmation |

Installed games, Proton prefixes and per-game shortcuts are **never** removed – only the launcher itself.

## 🏗 Building from Source
To build the launcher, you will need [DevelNext](https://develnext.org):
1. Open DevelNext
2. Clone the repository to any folder on your disk:
```bash
git clone https://github.com/nizar2004/onlinefix-linux
```
3. Open the `.dnproject` file in DevelNext
4. A message about missing dependencies will appear, install them in the `Project > Packages` tab:
	- [jphp-animatefx-ext](https://github.com/jphp-group/jphp-animatefx-ext/releases)
	- [jphp-controlsfx-ext](https://github.com/jphp-group/jphp-controlsfx-ext/releases)
	- [jphp-vdf-ext](https://github.com/GIGNIGHT/jphp-vdf-ext) (manual compilation to `dnbundle` via [jppm](https://github.com/jphp-group/jphp/releases) is required)
	- [jphp-websocket-client](https://github.com/jphp-group/jphp-websocket-client/releases)
5. Click the build button at the top of the window

After building, you will get the launcher executable file, and you can install it with:

```bash
./install.sh --jar /path/to/OFMELauncher.jar
```

## 📄 License
[GNU AGPL v3](LICENSE) – the original project and this fork are both licensed under the AGPL-3.0.
