#!/bin/bash
# Network speed monitor for waybar

interface=$(ip route | grep '^default' | awk '{print $5}' | head -1)
[ -z "$interface" ] && echo '{"text": "  󰤮  ", "tooltip": "No interface"}' && exit 0

rx1=$(cat /sys/class/net/"$interface"/statistics/rx_bytes)
tx1=$(cat /sys/class/net/"$interface"/statistics/tx_bytes)
sleep 1
rx2=$(cat /sys/class/net/"$interface"/statistics/rx_bytes)
tx2=$(cat /sys/class/net/"$interface"/statistics/tx_bytes)

rx_diff=$((rx2 - rx1))
tx_diff=$((tx2 - tx1))

format_speed() {
  local bytes=$1
  if [ "$bytes" -gt 1048576 ]; then
    echo "$(awk "BEGIN {printf \"%.1f\", $bytes/1048576}")MB/s"
  elif [ "$bytes" -gt 1024 ]; then
    echo "$(awk "BEGIN {printf \"%.0f\", $bytes/1024}")KB/s"
  else
    echo "${bytes}B/s"
  fi
}

down=$(format_speed $rx_diff)
up=$(format_speed $tx_diff)

echo "{\"text\": \" ↓$down ↑$up\", \"tooltip\": \"$interface: ↓$down / ↑$up\"}"
