#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "ERROR: Do not run this script as root. Run as a normal user (sudo will prompt)."
    exit 1
fi

if ! command -v pacman &>/dev/null; then
    echo "ERROR: pacman not found. This script only supports Arch Linux."
    exit 1
fi

AUR_PKGS=(base-devel git)

if ! command -v yay &>/dev/null; then
    echo ">>> yay (AUR helper) not found. Installing it first..."
    sudo pacman -S --needed --noconfirm "${AUR_PKGS[@]}"
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    cd /tmp/yay-bin && makepkg -si --noconfirm && cd - >/dev/null
    rm -rf /tmp/yay-bin
else
    MISSING=()
    for pkg in "${AUR_PKGS[@]}"; do
        pacman -Q "${pkg}" &>/dev/null || MISSING+=("${pkg}")
    done
    if [[ ${#MISSING[@]} -gt 0 ]]; then
        echo ">>> Installing AUR build requirements: ${MISSING[*]}"
        sudo pacman -S --needed --noconfirm "${MISSING[@]}"
    fi
fi

echo "=========================================================="
echo " Browser installer for this device (Arch Linux, x86_64)"
echo "=========================================================="
echo " 1) LibreWolf        (AUR: librewolf-bin)"
echo " 2) Tor Browser      (AUR: tor-browser-bin)"
echo " 3) Mullvad Browser  (AUR: mullvad-browser-bin)"
echo " 4) Firefox hardened (official + arkenfox user.js + uBlock)"
echo " 5) Brave            (AUR: brave-bin)"
echo " 6) Helium           (AUR: helium-browser-bin)"
echo "----------------------------------------------------------"
echo " Enter numbers separated by commas (e.g. 1,4,6)"
echo " 'a' = install all, 'q' = quit"
read -rp "> " SELECTION

case "${SELECTION,,}" in
    q|quit) echo "Aborted."; exit 0 ;;
    a|all)  CHOICES=(1 2 3 4 5 6) ;;
    *)
        IFS=', ' read -r -a CHOICES <<< "${SELECTION}"
        ;;
esac

installed() { yay -Q "$1" &>/dev/null; }

install_aur() {
    local pkg="$1" name="$2"
    if installed "$pkg"; then
        echo ">>> $name is already installed. Skipping."
    else
        echo ">>> Installing $name ($pkg)..."
        yay -S --needed --noconfirm "$pkg"
    fi
}

install_librewolf() { install_aur librewolf-bin "LibreWolf"; }
install_tor() { install_aur tor-browser-bin "Tor Browser"; }
install_mullvad() { install_aur mullvad-browser-bin "Mullvad Browser"; }
install_brave() { install_aur brave-bin "Brave"; }
install_helium() { install_aur helium-browser-bin "Helium"; }

install_firefox_hardened() {
    if ! installed firefox; then
        echo ">>> Installing Firefox (official repo)..."
        sudo pacman -S --needed --noconfirm firefox
    else
        echo ">>> Firefox already installed."
    fi

    local PROFILE_DIR="$HOME/.mozilla/firefox"
    local PROFNAME="hardened-$(date +%s)"
    mkdir -p "$PROFILE_DIR/$PROFNAME/extensions"

    if [[ -f "$PROFILE_DIR/profiles.ini" ]]; then
        cp "$PROFILE_DIR/profiles.ini" "$PROFILE_DIR/profiles.ini.bak-$(date +%s)"
        echo ">>> Backed up existing profiles.ini"
    fi

    {
        echo "[Profile0]"
        echo "Name=$PROFNAME"
        echo "IsRelative=1"
        echo "Path=$PROFNAME"
        echo "Default=1"
    } > "$PROFILE_DIR/profiles.ini"

    echo ">>> Downloading arkenfox user.js (hardening config)..."
    curl -fsSL -o "$PROFILE_DIR/$PROFNAME/user.js" \
        https://raw.githubusercontent.com/arkenfox/user.js/master/user.js

    echo ">>> Downloading uBlock Origin..."
    curl -fsSL -o "$PROFILE_DIR/$PROFNAME/extensions/uBlock0@raymondhill.net.xpi" \
        https://github.com/gorhill/uBlock/releases/latest/download/uBlock0_webext.firefox.signed.xpi

    echo ">>> Firefox hardened profile created: $PROFNAME"
}

echo ""
for c in "${CHOICES[@]}"; do
    case "$c" in
        1) install_librewolf ;;
        2) install_tor ;;
        3) install_mullvad ;;
        4) install_firefox_hardened ;;
        5) install_brave ;;
        6) install_helium ;;
        *) echo ">>> Ignoring invalid choice: $c" ;;
    esac
done

echo "=========================================================="
echo " SUCCESS! Installed browser(s):"
for c in "${CHOICES[@]}"; do
    case "$c" in
        1) echo "  - LibreWolf        (run: librewolf)" ;;
        2) echo "  - Tor Browser      (run: tor-browser)" ;;
        3) echo "  - Mullvad Browser  (run: mullvad-browser)" ;;
        4) echo "  - Firefox hardened (run: firefox)" ;;
        5) echo "  - Brave            (run: brave)" ;;
        6) echo "  - Helium           (run: helium)" ;;
    esac
done
echo " NOTE: On this Hyprland/Wayland setup, Firefox-based browsers"
echo " get Wayland support via: export MOZ_ENABLE_WAYLAND=1"
echo "=========================================================="
