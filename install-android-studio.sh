#!/usr/bin/env bash
set -euo pipefail

ANDROID_STUDIO_VERSION="2024.2.2.14"
ANDROID_STUDIO_URL="https://redirector.gvt1.com/edgedl/android/studio/ide-zips/${ANDROID_STUDIO_VERSION}/android-studio-${ANDROID_STUDIO_VERSION}-linux.tar.gz"
INSTALL_DIR="/opt/android-studio"
ANDROID_HOME="${HOME}/Android/Sdk"
DESKTOP_FILE="${HOME}/.local/share/applications/android-studio.desktop"
ICON_PATH="${INSTALL_DIR}/bin/studio.png"
STUDIO_SCRIPT="${INSTALL_DIR}/bin/studio.sh"

setup_color() {
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'
    BOLD='\033[1m'
}

log_info()  { echo -e "${CYAN}[INFO]${NC}  $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

install_system_deps() {
    log_info "Installing system dependencies..."

    local deps=(
        jdk21-openjdk
        libxcrypt-compat
        libx11
        libxext
        libxrender
        libxtst
        libxi
        libxft
        libxrandr
        libxcomposite
        libxdamage
        libxfixes
        libxcb
        gtk3
        glib2
        nss
        nspr
        atk
        at-spi2-atk
        at-spi2-core
        cups
        libdrm
        mesa
        dbus
        alsa-lib
        pcsclite
        wget
        tar
        gzip
    )

    sudo pacman -S --needed --noconfirm "${deps[@]}"
    log_ok "System dependencies installed."
}

ensure_yay() {
    if command -v yay &>/dev/null; then
        log_ok "yay already installed."
        return
    fi

    log_info "yay not found. Installing yay from AUR..."
    local tmp
    tmp=$(mktemp -d)
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay.git "$tmp/yay"
    (cd "$tmp/yay" && makepkg -si --noconfirm)
    rm -rf "$tmp"
    log_ok "yay installed."
}

install_android_studio() {
    if [[ -d "$INSTALL_DIR" ]]; then
        log_warn "Android Studio already installed at ${INSTALL_DIR}. Skipping download."
        return
    fi

    local archive="/tmp/android-studio.tar.gz"
    log_info "Downloading Android Studio ${ANDROID_STUDIO_VERSION}..."
    wget -O "$archive" "$ANDROID_STUDIO_URL" --progress=bar:force 2>&1

    log_info "Extracting to ${INSTALL_DIR}..."
    sudo tar -xzf "$archive" -C /opt/
    sudo chown -R root:root "$INSTALL_DIR"
    log_ok "Android Studio installed at ${INSTALL_DIR}."
    rm -f "$archive"
}

create_symlink() {
    local link="/usr/local/bin/studio"
    if [[ -L "$link" ]]; then
        log_info "Symlink already exists at ${link}."
        return
    fi
    sudo ln -sf "$STUDIO_SCRIPT" "$link"
    log_ok "Symlink created: ${link} -> ${STUDIO_SCRIPT}"
}

setup_desktop_entry() {
    [[ -f "$DESKTOP_FILE" ]] && { log_info "Desktop entry already exists."; return; }

    mkdir -p "$(dirname "$DESKTOP_FILE")"

    cat > "$DESKTOP_FILE" <<DESKTOP
[Desktop Entry]
Version=1.0
Type=Application
Name=Android Studio
Comment=Android Studio IDE
Exec=${STUDIO_SCRIPT} %f
Icon=${ICON_PATH}
Categories=Development;IDE;
Terminal=false
StartupNotify=true
StartupWMClass=jetbrains-android-studio
MimeType=text/plain;
DESKTOP
    chmod +x "$DESKTOP_FILE"
    log_ok "Desktop entry created at ${DESKTOP_FILE}."
}

setup_environment() {
    local bashrc="${HOME}/.bashrc"
    local zshrc="${HOME}/.zshrc"
    local rcfile=""

    if [[ -f "$zshrc" ]]; then
        rcfile="$zshrc"
    elif [[ -f "$bashrc" ]]; then
        rcfile="$bashrc"
    else
        rcfile="$bashrc"
    fi

    local line_android="export ANDROID_HOME=\${HOME}/Android/Sdk"
    local line_path='export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator'

    if grep -q "ANDROID_HOME" "$rcfile" 2>/dev/null; then
        log_info "Environment variables already set in ${rcfile}."
        return
    fi

    {
        echo ""
        echo "# Android Studio / SDK"
        echo "$line_android"
        echo "$line_path"
    } >> "$rcfile"

    log_ok "Environment variables added to ${rcfile}."
    log_warn "Run 'source ${rcfile}' or restart your shell to apply."
}

install_cmdline_tools() {
    local sdkmanager="${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager"
    if [[ -x "$sdkmanager" ]]; then
        log_info "cmdline-tools already installed."
        return
    fi

    log_info "Installing Android cmdline-tools..."
    mkdir -p "$ANDROID_HOME/cmdline-tools"
    local tmp
    tmp=$(mktemp -d)
    wget -O "$tmp/cmdline-tools.zip" "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    unzip -q "$tmp/cmdline-tools.zip" -d "$tmp/"
    mv "$tmp/cmdline-tools" "${ANDROID_HOME}/cmdline-tools/latest"
    rm -rf "$tmp"

    log_info "Accepting licenses and installing basic SDK components..."
    yes | "$sdkmanager" --sdk_root="$ANDROID_HOME" "platforms;android-35" "platform-tools" "emulator" "build-tools;35.0.0" 2>/dev/null
    log_ok "Android SDK components installed."
}

main() {
    setup_color
    echo -e "${BOLD}Android Studio Auto-Installer for Arch Linux${NC}"
    echo ""

    install_system_deps
    ensure_yay
    install_android_studio
    create_symlink
    setup_desktop_entry
    setup_environment
    install_cmdline_tools

    echo ""
    echo -e "${GREEN}${BOLD}All done!${NC}"
    echo -e "  Launch:  ${CYAN}studio${NC} or find 'Android Studio' in your app launcher."
    echo -e "  SDK at:  ${CYAN}${ANDROID_HOME}${NC}"
    echo ""
}

main "$@"