#!/bin/bash

set -e

NM_CONF="/etc/NetworkManager/conf.d/90-wifi-fix.conf"

if [ -f "$NM_CONF" ]; then
    echo "[*] WiFi fix config already exists: $NM_CONF"
    echo "[*] Contents:"
    cat "$NM_CONF"
    exit 0
fi

echo "[*] Creating NetworkManager config to disable MAC randomization..."

cat << 'EOF' | sudo tee "$NM_CONF" > /dev/null
[device]
# Disable MAC randomization during Wi-Fi scanning
# This prevents NM from changing the MAC every ~7 minutes,
# which was causing deauth/reconnect cycles that broke active connections
wifi.scan-rand-mac-address=no

[keyfile]
# iwd handles our WiFi connection; NM should not manage wlan0
unmanaged-devices=interface-name:wlan0
EOF

echo "[*] Restarting NetworkManager..."
sudo systemctl restart NetworkManager

echo "[+] Done! wlan0 is now unmanaged by NetworkManager."
echo "    Verify with: nmcli device status"
