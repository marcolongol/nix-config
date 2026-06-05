#!/usr/bin/env bash
# Unified rofi power menu — replaces the waybar power-group drawer.
# Single entry point, no nested confirms: dangerous actions ask once.
set -euo pipefail

# Glyph + label pairs (Nerd Font v3). Label-only string goes to rofi so the
# glyph stays in front of the human-readable name.
declare -a entries=(
  "  Lock"
  "󰤄  Suspend"
  "󰍃  Logout"
  "󰜉  Reboot"
  "  Shutdown"
)

choice=$(printf '%s\n' "${entries[@]}" \
  | rofi -dmenu \
         -p "Power" \
         -i \
         -no-custom \
         -theme-str 'window { width: 280px; }')

# Strip the leading icon + 2 spaces to get the bare action name.
action="${choice##*  }"

confirm() {
  local prompt="$1"
  local pick
  pick=$(printf 'No\nYes\n' | rofi -dmenu -p "$prompt" -no-custom)
  [[ "$pick" == "Yes" ]]
}

case "$action" in
  Lock)     hyprlock & disown ;;
  Suspend)  systemctl suspend ;;
  Logout)   confirm "Quit Hyprland?" && hyprctl dispatch exit ;;
  Reboot)   confirm "Reboot?"        && systemctl reboot ;;
  Shutdown) confirm "Shutdown?"      && systemctl poweroff ;;
  "")       exit 0 ;;
  *)        notify-send "rofi-power" "Unknown action: $action" ;;
esac
