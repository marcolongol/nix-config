#!/usr/bin/env bash
# Toggle a systemd-inhibit lock for idle, sleep, and lid-switch handling.
# Used by waybar in place of the built-in idle_inhibitor module so that
# closing the laptop lid is also blocked while the toggle is active.
set -euo pipefail

PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-inhibit.pid"
SIGNAL=11

is_active() {
  [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null
}

start() {
  systemd-inhibit \
    --what=idle:sleep:handle-lid-switch \
    --who=waybar \
    --why="user toggle" \
    --mode=block \
    sleep infinity &
  echo $! >"$PIDFILE"
  disown
}

stop() {
  if [[ -f "$PIDFILE" ]]; then
    kill "$(cat "$PIDFILE")" 2>/dev/null || true
    rm -f "$PIDFILE"
  fi
}

print_status() {
  if is_active; then
    printf '{"text":"󰅶","alt":"activated","class":"activated","tooltip":"Inhibit: ON (idle, sleep, lid-switch all blocked)"}\n'
  else
    # Clean stale pidfile if the held process is gone.
    [[ -f "$PIDFILE" ]] && rm -f "$PIDFILE"
    printf '{"text":"󰾪","alt":"deactivated","class":"deactivated","tooltip":"Inhibit: OFF (sleep/lid allowed)"}\n'
  fi
}

case "${1:-status}" in
  toggle)
    if is_active; then stop; else start; fi
    pkill -RTMIN+$SIGNAL waybar 2>/dev/null || true
    ;;
  status) print_status ;;
  *)
    echo "usage: $(basename "$0") {toggle|status}" >&2
    exit 2
    ;;
esac
