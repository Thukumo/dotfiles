#!/usr/bin/env bash
set -euo pipefail

if bat="$(acpi -b 2>/dev/null | sed -n '1{s/^Battery [0-9]*: //;p}')" && [ -n "$bat" ]; then
  echo "bat=$bat"
fi

iface="$(ip -4 -brief addr show scope global up 2>/dev/null | awk 'NR==1{print $1}')"
if [ -n "$iface" ]; then
  ip4="$(ip -4 -brief addr show "$iface" scope global | awk '{print $3}')"
  link="$(iw dev "$iface" link 2>/dev/null | sed -n 's/^[[:space:]]*SSID: //p')" || true
  sig="$(iw dev "$iface" link 2>/dev/null | sed -n 's/^[[:space:]]*signal: //p')" || true
  echo "net=${link:-$iface} $ip4${sig:+ ($sig)}"
else
  echo "net=オフライン"
fi

echo "load=$(cut -d' ' -f1-3 /proc/loadavg)"
echo "mem=$(free -h | awk '/^Mem:/{print $3 "/" $2}')"
echo "disk=$(df -h / | awk 'NR==2{print $5 " (" $3 "/" $2 ")"}')"

vol="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{printf "%d%%", $2*100; if ($3=="[MUTED]") printf " ミュート"}')"
if [ -n "$vol" ]; then
  echo "vol=$vol"
fi
