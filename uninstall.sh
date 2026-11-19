#!/usr/bin/env bash
#
# OnlineFix Linux Launcher - uninstaller
#
# Removes the files recorded by install.sh (launcher command, desktop entry,
# icon and application directory). User data in ~/.config/OFME-Linux is only
# removed when --purge is passed.
#
# Usage: ./uninstall.sh [options]
# Run ./uninstall.sh --help for the full option list.
#
set -euo pipefail

APP_NAME="OnlineFix Linux Launcher"
APP_ID="onlinefix-linux"
BIN_NAME="onlinefix-linux-launcher"
JAR_NAME="OFMELauncher.jar"
DEFAULT_REPO="nizar2004/onlinefix-linux"
DEFAULT_BRANCH="main"

MODE="user"
PREFIX=""
PURGE=0
FORCE=0
ASSUME_YES=0
DRY_RUN=0

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    C_RESET=$'\033[0m'
    C_BOLD=$'\033[1m'
    C_DIM=$'\033[2m'
    C_RED=$'\033[31m'
    C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m'
    C_CYAN=$'\033[36m'
else
    C_RESET=""
    C_BOLD=""
    C_DIM=""
    C_RED=""
    C_GREEN=""
    C_YELLOW=""
    C_CYAN=""
fi

say()   { printf '%s\n' "$*"; }
info()  { printf '%s==>%s %s\n' "$C_CYAN" "$C_RESET" "$*"; }
warn()  { printf '%s warning:%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
die()   { printf '%s error:%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

usage() {
    cat <<EOF
${C_BOLD}${APP_NAME} uninstaller${C_RESET}

Usage:
  ./uninstall.sh [options]

Options:
  --system       Uninstall a system-wide installation from /opt (uses sudo when needed).
  --prefix DIR   Uninstall from a custom prefix used with install.sh --prefix.
  --purge        Also delete user data in ~/.config/OFME-Linux
                 (game list, banners and extracted icons).
  --force        Continue even if the launcher is currently running.
  --dry-run      Show what would be removed without changing anything.
  -y, --yes      Do not ask for confirmation.
  -h, --help     Show this help.

Installed games, Proton prefixes and per-game shortcuts are never removed.

Examples:
  ./uninstall.sh
  ./uninstall.sh --purge
  ./uninstall.sh --system --yes

Environment:
  NO_COLOR     Disable colored output.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --system)
            MODE="system"; shift ;;
        --prefix)
            [ $# -ge 2 ] || die "--prefix needs a directory"
            PREFIX="$2"; shift 2 ;;
        --prefix=*)
            PREFIX="${1#*=}"; shift ;;
        --purge)
            PURGE=1; shift ;;
        --force)
            FORCE=1; shift ;;
        --dry-run)
            DRY_RUN=1; shift ;;
        -y|--yes)
            ASSUME_YES=1; shift ;;
        -h|--help)
            usage; exit 0 ;;
        *)
            die "Unknown option: $1 (try --help)" ;;
    esac
done

if [ -n "$PREFIX" ]; then
    case "$PREFIX" in
        /*) ;;
        *) PREFIX="$PWD/$PREFIX" ;;
    esac
    PREFIX="${PREFIX%/}"
fi

SUDO=""
if [ "$MODE" = "system" ] && [ "$(id -u)" -ne 0 ]; then
    command -v sudo >/dev/null 2>&1 || die "--system needs root privileges, and sudo was not found"
    SUDO="sudo"
fi
run() {
    if [ -n "$SUDO" ]; then
        "$SUDO" "$@"
    else
        "$@"
    fi
}

if [ -n "$PREFIX" ]; then
    APP_DIR="$PREFIX/opt/$APP_ID"
    BIN_DIR="$PREFIX/bin"
    SHARE_DIR="$PREFIX/share"
elif [ "$MODE" = "system" ]; then
    APP_DIR="/opt/$APP_ID"
    BIN_DIR="/usr/local/bin"
    SHARE_DIR="/usr/share"
else
    DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
    BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
    APP_DIR="$DATA_HOME/$APP_ID"
    SHARE_DIR="$DATA_HOME"
fi

DESKTOP_DIR="$SHARE_DIR/applications"
ICON_DIR="$SHARE_DIR/icons/hicolor/128x128/apps"
MANIFEST="$APP_DIR/install.env"

if [ ! -f "$MANIFEST" ]; then
    cat >&2 <<EOF
${C_RED}error:${C_RESET} No installation manifest found at:
  $MANIFEST

Nothing was removed. Installations made with install.sh are removed from here.
Hints:
  - system-wide install:   $0 --system
  - custom prefix:         $0 --prefix /path/used/at/install
  - built-in installer / AUR: use the uninstaller that came with that package
EOF
    exit 1
fi

manifest_value() {
    sed -n "s/^$1=//p" "$MANIFEST" | head -n1
}

MANIFEST_APP_DIR="$(manifest_value APP_DIR)"
MANIFEST_BIN_FILE="$(manifest_value BIN_FILE)"
MANIFEST_DESKTOP_FILE="$(manifest_value DESKTOP_FILE)"
MANIFEST_ICON_FILE="$(manifest_value ICON_FILE)"

if [ -n "$MANIFEST_APP_DIR" ]; then
    APP_DIR="$MANIFEST_APP_DIR"
fi
if [ -n "$MANIFEST_BIN_FILE" ]; then
    BIN_FILE="$MANIFEST_BIN_FILE"
else
    BIN_FILE="$BIN_DIR/$BIN_NAME"
fi
if [ -n "$MANIFEST_DESKTOP_FILE" ]; then
    DESKTOP_FILE="$MANIFEST_DESKTOP_FILE"
else
    DESKTOP_FILE="$DESKTOP_DIR/$BIN_NAME.desktop"
fi
if [ -n "$MANIFEST_ICON_FILE" ]; then
    ICON_FILE="$MANIFEST_ICON_FILE"
else
    ICON_FILE="$ICON_DIR/$BIN_NAME.png"
fi

say "${C_BOLD}This will remove:${C_RESET}"
say "  launcher   $BIN_FILE"
say "  desktop    $DESKTOP_FILE"
say "  icon       $ICON_FILE"
say "  app files  $APP_DIR"
if [ "$PURGE" -eq 1 ]; then
    say "  user data  $HOME/.config/OFME-Linux (games, banners, icons)"
fi
say ""

if command -v pgrep >/dev/null 2>&1; then
    if pgrep -f "$APP_DIR/$JAR_NAME" >/dev/null 2>&1; then
        if [ "$FORCE" -ne 1 ]; then
            die "$APP_NAME is currently running. Close it first, or re-run with --force."
        fi
        warn "$APP_NAME is running; continuing because --force was given."
    fi
fi

if [ "$ASSUME_YES" -ne 1 ]; then
    if [ -t 0 ]; then
        printf 'Continue? [y/N] '
        read -r answer || answer=""
        case "$answer" in
            y|Y|yes|YES) ;;
            *) say "Cancelled."; exit 0 ;;
        esac
    else
        die "Refusing to uninstall without confirmation in a non-interactive shell. Re-run with --yes."
    fi
fi

remove_path() {
    local path="$1"
    [ -n "$path" ] || return 0
    if [ ! -e "$path" ] && [ ! -L "$path" ]; then
        return 0
    fi
    if [ "$DRY_RUN" -eq 1 ]; then
        say "would remove $path"
        return 0
    fi
    say "removing $path"
    run rm -rf -- "$path"
}

remove_path "$BIN_FILE"
remove_path "$DESKTOP_FILE"
remove_path "$ICON_FILE"
remove_path "$APP_DIR"

if [ "$PURGE" -eq 1 ]; then
    remove_path "$HOME/.config/OFME-Linux"
    remove_path "/tmp/ofllpid"
fi

if [ "$DRY_RUN" -eq 0 ]; then
    if command -v update-desktop-database >/dev/null 2>&1; then
        run update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true
    fi
    if command -v gtk-update-icon-cache >/dev/null 2>&1 && [ -d "$SHARE_DIR/icons/hicolor" ]; then
        run gtk-update-icon-cache -f -t "$SHARE_DIR/icons/hicolor" >/dev/null 2>&1 || true
    fi
fi

if [ "$DRY_RUN" -eq 1 ]; then
    printf '\n%sDry run complete; nothing was changed.%s\n' "$C_GREEN" "$C_RESET"
else
    printf '\n%s%s was uninstalled.%s\n' "$C_GREEN" "$APP_NAME" "$C_RESET"
    if [ "$PURGE" -eq 0 ]; then
        say "User settings in ~/.config/OFME-Linux were kept. Use --purge to remove them."
    fi
    say "Installed games and Proton prefixes were not touched."
fi
