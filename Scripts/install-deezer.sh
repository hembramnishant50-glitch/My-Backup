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
echo " Deezer installer for this device"
echo "=========================================================="
if yay -Q deezer &>/dev/null; then
    echo ">>> Deezer is already installed. Skipping."
else
    echo ">>> Checking Deezer download server accessibility..."
    if curl -sIL --max-time 20 "https://www.deezer.com/desktop/download/artifact-win32-x86" \
        | grep -qiE 'deezer\.com/soon'; then
        echo ""
        echo "=========================================================="
        echo " GEO-BLOCKED: Deezer is not available in your region."
        echo ""
        echo " The AUR package must download Deezer's Windows installer"
        echo " (deezer-7.1.290-setup.exe) from www.deezer.com, but your"
        echo " IP is redirected to deezer.com/soon ('available soon in"
        echo " your country'), so only an HTML stub downloads and the"
        echo " sha256 check fails."
        echo ""
        echo " FIX: connect a VPN to a Deezer-supported country"
        echo " (e.g. US/EU) and re-run this script. Your own installer:"
        echo "     bash ~/Documents/MySetUp/install-vpn.sh"
        echo " Or use the Deezer web app in a browser until then."
        echo "=========================================================="
        exit 1
    fi
    echo ">>> Purging any previously-downloaded stub file..."
    rm -f "$HOME/.cache/yay/deezer/"*-setup.exe
    echo ">>> Installer server reachable. Installing Deezer (AUR)..."
    yay -S --needed --noconfirm deezer
fi

echo "=========================================================="
if command -v deezer &>/dev/null; then
    echo " SUCCESS! Deezer installed."
    echo " Launch it from your app menu or run: deezer"
    echo " NOTE: On Wayland, set the DEEZER_AUDIO_DRIVER if audio issues"
    echo " occur: export DEEZER_AUDIO_DRIVER=pulse"
else
    echo " WARNING: deezer binary not found in PATH after install."
    echo " Re-check with: yay -Qi deezer"
fi
echo "=========================================================="
