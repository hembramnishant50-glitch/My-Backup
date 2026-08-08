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
echo " WireGuard / OpenVPN installer for this device"
echo " Detected network stack: systemd-networkd + iwd"
echo " DNS: systemd-resolved (active)"
echo "=========================================================="
echo " 1) Install WireGuard"
echo " 2) Install OpenVPN"
echo " 3) Install both"
echo " 4) Quit"
read -rp " Choose [1-4]: " CHOICE

install_wireguard() {
    echo ">>> Installing WireGuard..."
    sudo pacman -S --needed --noconfirm wireguard-tools
    echo ">>> Kernel support is built-in (you run $(uname -r)); no DKMS needed."
    echo ">>> Usage:"
    echo "    wg genkey | tee private.key | wg pubkey > public.key"
    echo "    sudo wg-quick up /path/to/wg0.conf"
    echo "    sudo wg show"
}

install_openvpn() {
    echo ">>> Installing OpenVPN + systemd-resolvconf (DNS hook for systemd-resolved)..."
    sudo pacman -S --needed --noconfirm openvpn systemd-resolvconf
    echo ">>> Usage:"
    echo "    sudo cp /path/to/client.ovpn /etc/openvpn/client/client.conf"
    echo "    sudo systemctl enable --now openvpn-client@client"
    echo "    systemctl status openvpn-client@client"
}

case "${CHOICE}" in
    1) install_wireguard ;;
    2) install_openvpn ;;
    3) install_wireguard; install_openvpn ;;
    4) echo "Aborted."; exit 0 ;;
    *) echo "Invalid choice."; exit 1 ;;
esac

echo "=========================================================="
echo " SUCCESS! Verify your setup:"
echo "   WireGuard: wg show"
echo "   OpenVPN  : systemctl status openvpn-client@client"
echo "=========================================================="
