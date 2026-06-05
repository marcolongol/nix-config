#!/usr/bin/env bash
# Bluetooth picker mirroring rofi-wifi.py UX. Uses bluetoothctl + rofi -dmenu.
set -euo pipefail

power_on() { bluetoothctl show | grep -q "Powered: yes"; }
toggle_power() {
  if power_on; then
    bluetoothctl power off >/dev/null
  else
    bluetoothctl power on  >/dev/null
  fi
}

scan_devices() {
  bluetoothctl --timeout 6 scan on >/dev/null 2>&1 &
  notify-send "Bluetooth" "Scanning 6s…" -t 6000 -i bluetooth
  wait
}

# Device entries: "<icon>  <name>  <mac>  [status]"
list_devices() {
  bluetoothctl devices | while read -r _ mac name; do
    [[ -z "$mac" ]] && continue
    connected=$(bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes" && echo "󰂱" || echo "󰂯")
    echo "$connected  $name  $mac"
  done
}

main_menu() {
  local power_label
  if power_on; then power_label="󰂲  Turn Bluetooth OFF"; else power_label="󰂯  Turn Bluetooth ON"; fi

  local entries=()
  entries+=("$power_label")
  entries+=("󰜫  Scan for devices")
  if power_on; then
    while IFS= read -r line; do entries+=("$line"); done < <(list_devices)
  fi

  printf '%s\n' "${entries[@]}" \
    | rofi -dmenu -p "Bluetooth" -i -theme-str 'window { width: 420px; }'
}

choice=$(main_menu)
[[ -z "$choice" ]] && exit 0

case "$choice" in
  *"Turn Bluetooth"*) toggle_power ;;
  *"Scan for"*)       scan_devices ;;
  *)
    mac=$(awk '{print $NF}' <<<"$choice")
    if bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes"; then
      bluetoothctl disconnect "$mac" >/dev/null && \
        notify-send "Bluetooth" "Disconnected $mac" -i bluetooth
    else
      if bluetoothctl connect "$mac" >/dev/null 2>&1; then
        notify-send "Bluetooth" "Connected $mac" -i bluetooth
      else
        notify-send "Bluetooth" "Failed to connect $mac" -u critical -i bluetooth
      fi
    fi
    ;;
esac
