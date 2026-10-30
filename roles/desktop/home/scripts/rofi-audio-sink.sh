#!/usr/bin/env bash
# Unified audio picker: choose the default output (sink) or input (source).
# pw-dump for the node list (so filter-hosted nodes like the bluetooth HFP mic
# are included) + rofi -dmenu. Mirrors rofi-bluetooth.sh UX.
set -euo pipefail

ICON_OUT=$'\xf3\xb0\x95\xbe'   # 󰕾 volume-high
ICON_IN=$'\xf3\xb0\x8d\xac'    # 󰍬 microphone
DOT_ACTIVE=$'\xe2\x97\x8f'     # ● current default

# Emit "TYPE<TAB>ACTIVE<TAB>ID<TAB>DESC" for every Audio/Sink and Audio/Source
# node, marking the current default of each kind. Monitor sources are skipped.
list_nodes() {
  pw-dump | python3 -c '
import json, sys

objs = json.load(sys.stdin)
defaults = {}
nodes = []

for o in objs:
    t = o.get("type", "")
    if t.endswith("Metadata"):
        for e in o.get("metadata") or []:
            if e.get("key") in ("default.audio.sink", "default.audio.source"):
                v = e.get("value")
                if isinstance(v, str):
                    try:
                        v = json.loads(v)
                    except ValueError:
                        pass
                if isinstance(v, dict):
                    v = v.get("name")
                defaults[e["key"]] = v
    elif t.endswith("Node"):
        p = (o.get("info") or {}).get("props") or {}
        cls = p.get("media.class", "")
        if cls not in ("Audio/Sink", "Audio/Source"):
            continue
        name = p.get("node.name", "")
        if name.endswith(".monitor"):
            continue
        desc = p.get("node.description") or p.get("node.nick") or name
        nodes.append((cls, o.get("id"), name, desc))

for cls, nid, name, desc in nodes:
    typ = "out" if cls == "Audio/Sink" else "in"
    dkey = "default.audio." + ("sink" if typ == "out" else "source")
    active = "1" if defaults.get(dkey) == name else "0"
    print(f"{typ}\t{active}\t{nid}\t{desc}")
'
}

# Format tab-rows of one type into menu lines: "<dot> <icon>  <desc>  <id>".
fmt() {
  local icon="$1"
  while IFS=$'\t' read -r _sec active id desc; do
    [[ -z "$id" ]] && continue
    local dot=" "
    [[ "$active" == "1" ]] && dot="$DOT_ACTIVE"
    printf '%s %s  %s  %s\n' "$dot" "$icon" "$desc" "$id"
  done
}

nodes=$(list_nodes)
out=$(awk -F'\t' '$1 == "out"' <<<"$nodes")
in=$(awk -F'\t' '$1 == "in"' <<<"$nodes")

menu=$(
  printf '%s\n' "── Output ──"
  fmt "$ICON_OUT" <<<"$out"
  printf '%s\n' "── Input ──"
  fmt "$ICON_IN" <<<"$in"
)

choice=$(printf '%s\n' "$menu" | rofi -dmenu -p "Audio" -i -theme-str 'window { width: 480px; }')
[[ -z "$choice" ]] && exit 0

id=$(awk '{print $NF}' <<<"$choice")
[[ "$id" =~ ^[0-9]+$ ]] || exit 0   # header row or junk selected

wpctl set-default "$id"

line=$(awk -F'\t' -v id="$id" '$3 == id { print; exit }' <<<"$nodes")
typ=$(cut -f1 <<<"$line")
desc=$(cut -f4 <<<"$line")
if [[ "$typ" == "in" ]]; then
  notify-send "Audio Input" "Switched to $desc" -i audio-input-microphone
else
  notify-send "Audio Output" "Switched to $desc" -i audio-speakers
fi
