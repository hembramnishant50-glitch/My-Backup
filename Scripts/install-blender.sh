#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "ERROR: Do not run this script as root. Run it as a normal user (sudo will prompt for your password)."
    exit 1
fi

if ! command -v pacman &>/dev/null; then
    echo "ERROR: pacman not found. This script only supports Arch Linux."
    exit 1
fi

echo "=============================================="
echo " Blender auto-installer for Arch Linux"
echo "=============================================="
echo "GPU   : $(lspci | grep -iE 'vga|3d|display' | head -1 | sed 's/.*controller: //')"
echo "CPU   : $(nproc) cores"
echo "RAM   : $(free -h | awk '/Mem/{print $2}')"
echo "Mesa  : $(pacman -Q mesa 2>/dev/null | cut -d' ' -f2 || echo MISSING)"
echo "----------------------------------------------"

CORE=(
    blender
    mesa
    vulkan-radeon
    lib32-mesa
    ffmpeg
    xdg-desktop-portal-gtk
    xdg-utils
    file
)

MISSING=()
for pkg in "${CORE[@]}"; do
    if ! pacman -Q "${pkg}" &>/dev/null; then
        MISSING+=("${pkg}")
    fi
done

if [[ ${#MISSING[@]} -eq 0 ]]; then
    echo "All required packages are already installed. Nothing to do."
else
    echo "Installing missing packages: ${MISSING[*]}"
    echo "----------------------------------------------"
    sudo pacman -S --needed --noconfirm "${CORE[@]}"
fi

echo "=============================================="
echo " Verifying installation"
echo "=============================================="
if command -v blender &>/dev/null; then
    blender --version 2>/dev/null | head -2 || echo "blender binary found (version check needs a display)."
else
    echo "ERROR: blender binary not found after install. Try: sudo pacman -S blender"
    exit 1
fi

echo "----------------------------------------------"
echo " SUCCESS! Blender is installed."
echo " Launch it from your app menu or run: blender"
echo ""
echo " NOTE: Your AMD GPU uses the open-source mesa + vulkan-radeon"
echo " drivers, which are already installed and work out of the box."
echo " Cycles GPU rendering (HIP) is NOT enabled by this script;"
echo " CPU rendering works on all 12 cores immediately."
echo "----------------------------------------------"
