#!/usr/bin/env bash
# Audio output picker mirroring rofi-bluetooth.sh UX. Uses wpctl + rofi -dmenu.
set -euo pipefail

# List sinks: "<icon>  <description>  <id>" ; active sink marked.
list_sinks() {
  wpctl status | awk '
    /Sinks:/        { insinks = 1; next }
    /Sources:/      { insinks = 0 }
    insinks && /[0-9]+\. / {
      active = ($0 ~ /\*/) ? "\xef\x80\xa8" : "\xf3\xb0\x95\xbe"   # 󰕾 active /  speaker idle
      id = ""
      desc = ""
      for (i = 1; i <= NF; i++) {
        if ($i ~ /^[0-9]+\.$/) { id = $i; sub(/\./, "", id); start = i + 1; break }
      }
      for (i = start; i <= NF; i++) {
        if ($i ~ /\[vol:/) break
        desc = desc (desc == "" ? "" : " ") $i
      }
      printf "%s  %s  %s\n", active, desc, id
    }'
}

choice=$(list_sinks | rofi -dmenu -p "Audio Out" -i -theme-str 'window { width: 480px; }')
[[ -z "$choice" ]] && exit 0

id=$(awk '{print $NF}' <<<"$choice")
[[ -z "$id" ]] && exit 0

wpctl set-default "$id"
desc=$(sed -E 's/^[^ ]+  (.*)  [0-9]+$/\1/' <<<"$choice")
notify-send "Audio Output" "Switched to $desc" -i audio-speakers
