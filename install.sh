#!/usr/bin/env bash
#
# OnlineFix Linux Launcher - installer
#
# Installs a prebuilt OFMELauncher.jar (from a local DevelNext build or from a
# GitHub release), creates the launcher command, a desktop entry and an icon.
#
# Usage: ./install.sh [options]
# Run ./install.sh --help for the full option list.
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
JAR_SOURCE=""
JAR_URL=""
REPO="${OFME_REPO:-$DEFAULT_REPO}"
TAG=""
ASSUME_YES=0
SKIP_DEPS=0

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
${C_BOLD}${APP_NAME} installer${C_RESET}

Usage:
  ./install.sh [options]

Options:
  --jar FILE           Install a local OFMELauncher.jar instead of downloading one.
  --url URL            Download the launcher JAR from a direct URL.
  --repo OWNER/REPO    GitHub repository to download the latest release from
                       (default: $DEFAULT_REPO).
  --tag TAG            Use a specific release tag instead of the latest one.
  --system             Install system-wide in /opt (uses sudo when needed).
  --prefix DIR         Install under a custom prefix (DIR/opt, DIR/bin, DIR/share).
  --skip-deps          Do not check for ffmpeg/steam/optional tools.
  -y, --yes            Assume "yes" for prompts (the installer normally asks none).
  -h, --help           Show this help.

The JAR is resolved in this order:
  1. --jar FILE or --url URL (or the OFME_JAR environment variable)
  2. a local build: ./OFMELauncher.jar, ./build/OFMELauncher.jar, ./dist/OFMELauncher.jar
  3. the newest *.jar asset of the --repo GitHub release

Default user install locations:
  app            ~/.local/share/$APP_ID
  command        ~/.local/bin/$BIN_NAME
  desktop entry  ~/.local/share/applications/$BIN_NAME.desktop
  icon           ~/.local/share/icons/hicolor/128x128/apps/$BIN_NAME.png

Examples:
  ./install.sh
  ./install.sh --jar /path/to/OFMELauncher.jar
  ./install.sh --system
  ./install.sh --repo ZzEdovec/onlinefix-linux   # upstream build

Environment:
  OFME_JAR     Path to a local launcher JAR (same as --jar).
  OFME_REPO    Default GitHub repository (same as --repo).
  GITHUB_TOKEN Token used for GitHub API requests (avoids rate limits).
  NO_COLOR     Disable colored output.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --jar)
            [ $# -ge 2 ] || die "--jar needs a file path"
            JAR_SOURCE="$2"; shift 2 ;;
        --jar=*)
            JAR_SOURCE="${1#*=}"; shift ;;
        --url)
            [ $# -ge 2 ] || die "--url needs a URL"
            JAR_URL="$2"; shift 2 ;;
        --url=*)
            JAR_URL="${1#*=}"; shift ;;
        --repo)
            [ $# -ge 2 ] || die "--repo needs OWNER/REPO"
            REPO="$2"; shift 2 ;;
        --repo=*)
            REPO="${1#*=}"; shift ;;
        --tag)
            [ $# -ge 2 ] || die "--tag needs a release tag"
            TAG="$2"; shift 2 ;;
        --tag=*)
            TAG="${1#*=}"; shift ;;
        --system)
            MODE="system"; shift ;;
        --prefix)
            [ $# -ge 2 ] || die "--prefix needs a directory"
            PREFIX="$2"; shift 2 ;;
        --prefix=*)
            PREFIX="${1#*=}"; shift ;;
        --skip-deps)
            SKIP_DEPS=1; shift ;;
        -y|--yes)
            ASSUME_YES=1; shift ;;
        -h|--help)
            usage; exit 0 ;;
        *)
            die "Unknown option: $1 (try --help)" ;;
    esac
done

[ -n "$REPO" ] || die "Repository name is empty"

if [ -z "$JAR_SOURCE" ] && [ -n "${OFME_JAR:-}" ]; then
    JAR_SOURCE="$OFME_JAR"
fi

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
DESKTOP_FILE="$DESKTOP_DIR/$BIN_NAME.desktop"
ICON_FILE="$ICON_DIR/$BIN_NAME.png"
BIN_FILE="$BIN_DIR/$BIN_NAME"

SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
fi
[ -n "$SCRIPT_DIR" ] || SCRIPT_DIR="$PWD"

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ofme-install.XXXXXX")"
cleanup() { rm -rf -- "$TMP_DIR"; }
trap cleanup EXIT

command -v install >/dev/null 2>&1 || die "The 'install' command is required (coreutils)"

find_local_jar() {
    local candidate
    for candidate in \
        "$SCRIPT_DIR/$JAR_NAME" \
        "$SCRIPT_DIR/build/$JAR_NAME" \
        "$SCRIPT_DIR/dist/$JAR_NAME" \
        "$SCRIPT_DIR/../$JAR_NAME" \
        "$PWD/$JAR_NAME"
    do
        if [ -f "$candidate" ]; then
            printf '%s' "$candidate"
            return 0
        fi
    done
    return 1
}

fetch() {
    local url="$1" out="$2"
    if command -v curl >/dev/null 2>&1; then
        curl -fL --retry 3 --connect-timeout 20 --progress-bar -o "$out" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$out" "$url"
    else
        return 1
    fi
}

api_get() {
    local url="$1"
    if command -v curl >/dev/null 2>&1; then
        if [ -n "${GITHUB_TOKEN:-}" ]; then
            curl -fsSL --connect-timeout 20 \
                -H "Accept: application/vnd.github+json" \
                -H "Authorization: Bearer $GITHUB_TOKEN" \
                "$url"
        else
            curl -fsSL --connect-timeout 20 \
                -H "Accept: application/vnd.github+json" \
                "$url"
        fi
    elif command -v wget >/dev/null 2>&1; then
        if [ -n "${GITHUB_TOKEN:-}" ]; then
            wget -qO- --header="Accept: application/vnd.github+json" \
                --header="Authorization: Bearer $GITHUB_TOKEN" "$url"
        else
            wget -qO- --header="Accept: application/vnd.github+json" "$url"
        fi
    else
        return 1
    fi
}

download_release() {
    local api json url direct
    if [ -n "$TAG" ]; then
        api="https://api.github.com/repos/$REPO/releases/tags/$TAG"
        direct="https://github.com/$REPO/releases/download/$TAG/$JAR_NAME"
    else
        api="https://api.github.com/repos/$REPO/releases/latest"
        direct="https://github.com/$REPO/releases/latest/download/$JAR_NAME"
    fi

    json="$(api_get "$api" 2>/dev/null || true)"
    url=""
    if [ -n "$json" ]; then
        url="$(printf '%s\n' "$json" \
            | grep -o '"browser_download_url"[[:space:]]*:[[:space:]]*"[^"]*"' \
            | sed -E 's/.*"(https:[^"]+)".*/\1/' \
            | grep -Ei '\.jar(\?|$)' \
            | head -n1 || true)"
    fi

    if [ -n "$url" ]; then
        info "Downloading $url"
        fetch "$url" "$TMP_DIR/$JAR_NAME" || die "Download failed: $url"
        return 0
    fi

    # The API may be unavailable (rate limit, offline); GitHub can serve the
    # release asset directly when it is named OFMELauncher.jar.
    info "Downloading $direct"
    if fetch "$direct" "$TMP_DIR/$JAR_NAME"; then
        return 0
    fi

    die "Could not find a launcher JAR in the releases of $REPO${TAG:+ (tag $TAG)}.

Build the launcher in DevelNext first, then run:
  $0 --jar /path/to/$JAR_NAME

Or install a release from another repository, for example:
  $0 --repo ZzEdovec/onlinefix-linux"
}

if [ -n "$JAR_URL" ]; then
    info "Downloading $JAR_URL"
    fetch "$JAR_URL" "$TMP_DIR/$JAR_NAME" || die "Download failed: $JAR_URL"
    JAR_SOURCE="$TMP_DIR/$JAR_NAME"
elif [ -n "$JAR_SOURCE" ]; then
    [ -f "$JAR_SOURCE" ] || die "Launcher JAR not found: $JAR_SOURCE"
else
    JAR_SOURCE="$(find_local_jar || true)"
    if [ -z "$JAR_SOURCE" ]; then
        info "No local build found; looking for a release in $REPO"
        download_release
        JAR_SOURCE="$TMP_DIR/$JAR_NAME"
    else
        info "Using local build: $JAR_SOURCE"
    fi
fi

[ "$(head -c 2 "$JAR_SOURCE" 2>/dev/null || true)" = "PK" ] \
    || die "$JAR_SOURCE does not look like a JAR/ZIP archive"

check_java() {
    local java_bin ver major
    java_bin="${OFME_JAVA:-}"
    if [ -z "$java_bin" ] && [ -n "${JAVA_HOME:-}" ] && [ -x "$JAVA_HOME/bin/java" ]; then
        java_bin="$JAVA_HOME/bin/java"
    fi
    if [ -z "$java_bin" ]; then
        java_bin="$(command -v java || true)"
    fi

    if [ -z "$java_bin" ]; then
        warn "Java was not found. Install a Java 8 runtime before starting the launcher."
        return
    fi

    ver="$("$java_bin" -version 2>&1 | head -n1 || true)"
    case "$ver" in
        *'"1.8.'*|*'"8.'*) major="8" ;;
        *'"'*)
            major="$(printf '%s' "$ver" | sed -n 's/.*version "\([0-9][0-9]*\).*/\1/p')"
            ;;
        *) major="" ;;
    esac

    if [ -n "$major" ] && [ "$major" != "8" ]; then
        warn "Java $major was found at $java_bin, but this JavaFX 8 application is tested with Java 8."
        warn "If the window fails to open, install a Java 8 runtime (for example jre8 / java-8-openjdk)."
    fi
}

check_deps() {
    local missing_req=() missing_opt=()

    for cmd in ffmpeg; do
        command -v "$cmd" >/dev/null 2>&1 || missing_req+=("$cmd")
    done
    if ! command -v steam >/dev/null 2>&1; then
        missing_req+=("steam")
    fi
    if [ "${#missing_req[@]}" -gt 0 ]; then
        warn "Missing required dependencies: ${missing_req[*]}"
        warn "Install them with your package manager before launching games."
    fi

    command -v aria2c     >/dev/null 2>&1 || missing_opt+=("aria2 (game downloads)")
    command -v icoextract >/dev/null 2>&1 || missing_opt+=("icoextract (icon extraction)")
    command -v unrar      >/dev/null 2>&1 || missing_opt+=("unrar (RAR installers)")

    if [ "${#missing_opt[@]}" -gt 0 ]; then
        warn "Optional tools that are not installed:"
        for item in "${missing_opt[@]}"; do
            warn "  - $item"
        done
    fi
}

check_java
if [ "$SKIP_DEPS" -ne 1 ]; then
    check_deps
fi

if [ -f "$APP_DIR/$JAR_NAME" ]; then
    info "Updating the existing installation in $APP_DIR"
else
    info "Installing $APP_NAME to $APP_DIR"
fi

run install -d -m 0755 "$APP_DIR"
run install -m 0644 "$JAR_SOURCE" "$APP_DIR/$JAR_NAME"
if [ -f "$SCRIPT_DIR/LICENSE" ]; then
    run install -m 0644 "$SCRIPT_DIR/LICENSE" "$APP_DIR/LICENSE"
fi

if [ -f "$APP_DIR/LICENSE" ]; then
    say "${C_DIM}License installed to $APP_DIR/LICENSE${C_RESET}"
fi

cat > "$TMP_DIR/$BIN_NAME" <<'WRAPPER'
#!/bin/sh
# Generated by the OnlineFix Linux Launcher installer.
# The launcher is a JavaFX 8 application; Java 8 is recommended.
JAR="@JAR@"

if [ -n "${OFME_JAVA:-}" ]; then
    JAVA="$OFME_JAVA"
elif [ -n "${JAVA_HOME:-}" ] && [ -x "$JAVA_HOME/bin/java" ]; then
    JAVA="$JAVA_HOME/bin/java"
else
    JAVA="java"
fi

# The launcher talks to Steam and works best on X11.
export GDK_BACKEND="${GDK_BACKEND:-x11}"

# Work around JavaFX/GTK breakage with the Turkish locale.
case "${LANG:-}" in
    tr_TR*) LANG="en_US.UTF-8"; export LANG ;;
esac

exec "$JAVA" -Dprism.forceGPU=true -jar "$JAR" "$@"
WRAPPER
JAR_PLACEHOLDER="$APP_DIR/$JAR_NAME"
JAR_PLACEHOLDER="${JAR_PLACEHOLDER//\\/\\\\}"
JAR_PLACEHOLDER="${JAR_PLACEHOLDER//&/\\&}"
JAR_PLACEHOLDER="${JAR_PLACEHOLDER//#/\\#}"
sed -i "s#@JAR@#$JAR_PLACEHOLDER#g" "$TMP_DIR/$BIN_NAME"

run install -d -m 0755 "$BIN_DIR"
run install -m 0755 "$TMP_DIR/$BIN_NAME" "$BIN_FILE"

case "$BIN_FILE" in
    *" "*) EXEC_LINE="\"$BIN_FILE\"" ;;
    *)     EXEC_LINE="$BIN_FILE" ;;
esac

cat > "$TMP_DIR/$BIN_NAME.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Version=1.0
Name=$APP_NAME
GenericName=Launch OnlineFixes on Linux
Comment=Play games with community multiplayer fixes on Linux
Exec=$EXEC_LINE
Icon=$BIN_NAME
Terminal=false
Categories=Game;Network;
StartupWMClass=org.develnext.jphp.ext.javafx.classes.UXApplication\$CustomApplication
DESKTOP

run install -d -m 0755 "$DESKTOP_DIR"
run install -m 0644 "$TMP_DIR/$BIN_NAME.desktop" "$DESKTOP_FILE"

ICON_SRC=""
for candidate in \
    "$SCRIPT_DIR/src/.data/img/oflogo.png" \
    "$SCRIPT_DIR/../src/.data/img/oflogo.png" \
    "$PWD/src/.data/img/oflogo.png"
do
    if [ -f "$candidate" ]; then
        ICON_SRC="$candidate"
        break
    fi
done

if [ -z "$ICON_SRC" ]; then
    icon_url="https://raw.githubusercontent.com/$REPO/$DEFAULT_BRANCH/src/.data/img/oflogo.png"
    if fetch "$icon_url" "$TMP_DIR/oflogo.png" 2>/dev/null; then
        ICON_SRC="$TMP_DIR/oflogo.png"
    else
        warn "Could not download the application icon; the desktop entry will use a generic icon."
    fi
fi

INSTALLED_ICON=""
if [ -n "$ICON_SRC" ]; then
    run install -d -m 0755 "$ICON_DIR"
    run install -m 0644 "$ICON_SRC" "$ICON_FILE"
    INSTALLED_ICON="$ICON_FILE"
fi

{
    echo "MODE=$MODE"
    echo "APP_DIR=$APP_DIR"
    echo "BIN_FILE=$BIN_FILE"
    echo "DESKTOP_FILE=$DESKTOP_FILE"
    echo "ICON_FILE=$INSTALLED_ICON"
    echo "REPO=$REPO"
    echo "TAG=${TAG:-latest}"
    echo "INSTALLED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$TMP_DIR/install.env"
run install -m 0644 "$TMP_DIR/install.env" "$APP_DIR/install.env"

if command -v update-desktop-database >/dev/null 2>&1; then
    run update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1 && [ -d "$SHARE_DIR/icons/hicolor" ]; then
    run gtk-update-icon-cache -f -t "$SHARE_DIR/icons/hicolor" >/dev/null 2>&1 || true
fi

if [ "$MODE" = "user" ] && [ -z "$PREFIX" ]; then
    case ":$PATH:" in
        *":$BIN_DIR:"*) ;;
        *) warn "$BIN_DIR is not in your PATH. Add it to run '$BIN_NAME' directly." ;;
    esac
fi

UNINSTALL_ARGS=""
if [ "$MODE" = "system" ]; then
    UNINSTALL_ARGS="--system"
fi
if [ -n "$PREFIX" ]; then
    UNINSTALL_ARGS="--prefix \"$PREFIX\""
fi

if [ -f "$SCRIPT_DIR/uninstall.sh" ]; then
    UNINSTALL_HINT="$SCRIPT_DIR/uninstall.sh"
else
    UNINSTALL_HINT="curl -fsSL https://raw.githubusercontent.com/$DEFAULT_REPO/$DEFAULT_BRANCH/uninstall.sh | bash -s --"
fi
if [ -n "$UNINSTALL_ARGS" ]; then
    UNINSTALL_HINT="$UNINSTALL_HINT $UNINSTALL_ARGS"
fi

printf '\n%s%s installed.%s\n\n' "$C_GREEN" "$APP_NAME" "$C_RESET"
say "  Launcher : $BIN_FILE"
say "  App files: $APP_DIR"
say "  Settings : $HOME/.config/OFME-Linux (created on first run)"
printf '\nStart it from your application menu, or run:\n  %s\n' "$BIN_FILE"
printf '\nUninstall it with:\n  %s\n' "$UNINSTALL_HINT"
