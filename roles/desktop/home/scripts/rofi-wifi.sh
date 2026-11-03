#!/usr/bin/env bash
# WiFi picker mirroring rofi-bluetooth.sh UX. Uses nmcli + rofi -dmenu.
set -euo pipefail

rescan() {
  nmcli device wifi rescan >/dev/null 2>&1 || true
  notify-send "WiFi" "Scanning…" -t 2000 -i network-wireless
}

# SSIDs in menu order (index i in rofi = ssids[i - 2], after Scan/Disconnect).
# nmcli -t escapes ":" and "\" in values; SSID is last, so `read` gives it
# the whole remainder, spaces and colons included.
ssids=()
rows=()
declare -A seen=()
while IFS=: read -r inuse signal security ssid; do
  ssid=${ssid//\\:/:}
  ssid=${ssid//\\\\/\\}
  [[ -z "$ssid" || -n "${seen[$ssid]:-}" ]] && continue
  seen[$ssid]=1
  lock=$([[ -z "$security" ]] && echo "󰕖" || echo "󰒃")
  dot=$([[ "$inuse" == "*" ]] && echo " ●" || true)
  ssids+=("$ssid")
  rows+=("$lock  $ssid  $signal%$dot")
done < <(nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID device wifi list | sort -t: -k2 -rn)

main_menu() {
  { echo "󰜫  Scan for networks"
    echo "󰖪  Disconnect"
    printf '%s\n' "${rows[@]}"
  } | rofi -dmenu -format i -p "WiFi" -i -theme-str 'window { width: 420px; }'
}

choice=$(main_menu) || exit 0
[[ -z "$choice" ]] && exit 0

case "$choice" in
  0)
    rescan
    exec "$0"
    ;;
  1)
    dev=$(nmcli -t -f DEVICE,TYPE device | awk -F: '$2 == "wifi" {print $1; exit}')
    [[ -n "$dev" ]] && nmcli device disconnect "$dev" >/dev/null \
      && notify-send "WiFi" "Disconnected" -i network-wireless
    ;;
  *)
    # -1 = typed text matching no row; a negative index would wrap around.
    ((choice >= 2)) || exit 0
    ssid=${ssids[choice - 2]:-}
    [[ -z "$ssid" ]] && exit 0
    if nmcli -t -f NAME connection show | grep -qxF "$ssid"; then
      nmcli connection up "$ssid" >/dev/null \
        && notify-send "WiFi" "Connected to $ssid" -i network-wireless
    elif nmcli device wifi connect "$ssid" >/dev/null 2>&1; then
      notify-send "WiFi" "Connected to $ssid" -i network-wireless
    else
      pass=$(rofi -dmenu -password -p "Password for $ssid")
      [[ -z "$pass" ]] && exit 0
      if nmcli device wifi connect "$ssid" password "$pass" >/dev/null 2>&1; then
        notify-send "WiFi" "Connected to $ssid" -i network-wireless
      else
        notify-send "WiFi" "Failed to connect to $ssid" -u critical -i network-wireless
      fi
    fi
    ;;
esac
