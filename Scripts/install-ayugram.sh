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

if ! sudo -v; then
    echo "ERROR: sudo required."
    exit 1
fi

echo "=========================================================="
echo " Full AyuGram installer"
echo "=========================================================="

echo ">>> Installing yay (AUR helper)..."
if ! command -v yay &>/dev/null; then
    echo "    yay not found. Installing it first..."
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    cd /tmp/yay-bin && makepkg -si --noconfirm && cd - >/dev/null
    rm -rf /tmp/yay-bin
else
    echo "    yay already installed."
fi

echo ">>> Installing qt6-imageformats (WEBP image plugin - required to avoid crash)..."
if pacman -Q qt6-imageformats &>/dev/null; then
    echo "    qt6-imageformats already installed."
else
    sudo pacman -S --needed --noconfirm qt6-imageformats
fi

echo ">>> Installing AyuGram from AUR..."
yay -S --needed --noconfirm ayugram-desktop-bin

echo ">>> Verifying WEBP image plugin..."
if [[ -f /usr/lib/qt6/plugins/imageformats/libqwebp.so ]]; then
    echo "    libqwebp.so present - emoji sprites will load correctly."
else
    echo "    WARNING: libqwebp.so not found. AyuGram may crash on launch."
fi

echo ">>> Clearing stale AyuGram data (if any)..."
if [[ -d "$HOME/.local/share/AyuGramDesktop" ]] && [[ -z "$(ls -A "$HOME/.local/share/AyuGramDesktop/tdata" 2>/dev/null)" ]]; then
    echo "    tdata is empty, keeping it."
else
    echo "    tdata contains data, leaving it untouched."
fi

echo "=========================================================="
echo " SUCCESS! AyuGram installed."
echo "=========================================================="
echo " NEXT STEPS:"
echo " 1) Launch: AyuGram"
echo " 2) First run: log in with your phone number."
echo "=========================================================="
