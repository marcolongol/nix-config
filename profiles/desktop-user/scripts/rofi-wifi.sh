#!/usr/bin/env bash
# WiFi picker mirroring rofi-bluetooth.sh UX. Uses nmcli + rofi -dmenu.
set -euo pipefail

rescan() {
  nmcli device wifi rescan >/dev/null 2>&1 || true
  notify-send "WiFi" "Scanning…" -t 2000 -i network-wireless
}

# Device entries: "<lock>  <ssid>  <signal>%  [active dot]". Skips hidden/dupes.
list_networks() {
  nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID device wifi list | sort -t: -k2 -rn \
    | awk -F: '!seen[$4]++ && $4 != "" {
        lock = ($3 == "") ? "󰕖" : "󰒃"
        dot  = ($1 == "*") ? " ●" : ""
        printf "%s  %s  %s%%%s\n", lock, $4, $2, dot
      }'
}

main_menu() {
  { echo "󰜫  Scan for networks"
    echo "󰖪  Disconnect"
    list_networks
  } | rofi -dmenu -p "WiFi" -i -theme-str 'window { width: 420px; }'
}

choice=$(main_menu)
[[ -z "$choice" ]] && exit 0

case "$choice" in
  *"Scan for"*)
    rescan
    exec "$0"
    ;;
  *"Disconnect"*)
    dev=$(nmcli -t -f DEVICE,TYPE device | awk -F: '$2 == "wifi" {print $1; exit}')
    [[ -n "$dev" ]] && nmcli device disconnect "$dev" >/dev/null \
      && notify-send "WiFi" "Disconnected" -i network-wireless
    ;;
  *)
    # Field 2 is the SSID (lock glyph is field 1, signal trails).
    ssid=$(awk '{print $2}' <<<"$choice")
    [[ -z "$ssid" ]] && exit 0
    # Known connection? bring it up. Else connect fresh (prompt password on fail).
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
