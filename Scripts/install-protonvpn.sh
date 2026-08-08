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

echo "=========================================================="
echo " Proton VPN (free tier) installer"
echo " Needed for: Deezer (and other geo-blocked apps)"
echo " Free servers: US / NL / JP - all Deezer-supported"
echo "=========================================================="

PKGS=(proton-vpn-cli proton-vpn-gtk-app)
MISSING=()
for pkg in "${PKGS[@]}"; do
    pacman -Q "${pkg}" &>/dev/null || MISSING+=("${pkg}")
done

if [[ ${#MISSING[@]} -eq 0 ]]; then
    echo ">>> Proton VPN already installed."
else
    echo ">>> Installing from official repos: ${MISSING[*]}"
    sudo pacman -S --needed --noconfirm "${MISSING[@]}"
fi

if ! systemctl is-active --quiet NetworkManager; then
    echo ">>> Note: NetworkManager is inactive on this device;"
    echo "    Proton VPN works with systemd-networkd too."
fi

echo ""
echo "=========================================================="
echo " NEXT STEPS (one-time, ~2 minutes):"
echo "----------------------------------------------------------"
echo " 1) Sign up for a FREE account (no card):"
echo "    https://account.proton.me/signup?plan=free"
echo ""
echo " 2) Log in with the CLI:"
echo "    protonvpn-cli login"
echo "    (enter your email + password; you may need the"
echo "     password you set in your free account)"
echo ""
echo " 3) Connect to a free US/NL server:"
echo "    protonvpn-cli connect"
echo ""
echo " 4) Now install Deezer (this is the important part):"
echo "    bash ~/Documents/MySetUp/install-deezer.sh"
echo ""
echo " 5) To disconnect later:"
echo "    protonvpn-cli disconnect"
echo ""
echo " NOTE: keep the VPN connected while using Deezer, since"
echo " streaming is also region-locked in India. For a GUI,"
echo " launch: protonvpn"
echo "=========================================================="
