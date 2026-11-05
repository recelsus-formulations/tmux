#!/bin/sh

set -eu

command -v tmux >/dev/null 2>&1 || exit 0
client=${1:-}
menu_x=${2:-C}
[ -n "$client" ] || exit 0
case "$menu_x" in
    C | R) ;;
    '' | *[!0-9]*) menu_x=C ;;
esac
sessions=$(tmux list-sessions -F '#{session_id} #{session_name}' 2>/dev/null) || exit 0
sorted_sessions=$(printf '%s\n' "$sessions" | LC_ALL=C sort -k2,2n) || exit 0
current_session=$(tmux display-message -p -c "$client" '#{session_id}') || exit 0

set -- display-menu -O -M -c "$client" -x "$menu_x" -y S \
    -T Sessions -s 'bg=colour237,fg=colour248' \
    -H 'bg=colour239,fg=colour255' -S 'fg=colour244' --
while IFS=' ' read -r session_id session_name; do
    marker=''
    if [ "$session_id" = "$current_session" ]; then
        marker=' *'
    fi
    label=$(printf 'Session %s%s' "$session_name" "$marker" | sed 's/#/##/g')
    set -- "$@" "$label" '' "switch-client -t '$session_id'"
done <<EOF
$sorted_sessions
EOF
tmux "$@"
