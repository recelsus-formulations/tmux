#!/bin/sh

set -eu

client=${1:-}
socket_path=${2:-}
[ -n "$client" ] && [ -n "$socket_path" ] || exit 0
command -v tmux >/dev/null 2>&1 || exit 0

# The running server may be older than the installed tmux command.
commands=$(tmux -S "$socket_path" list-commands 2>/dev/null) || exit 0
target_pane=$(tmux -S "$socket_path" display-message -p -c "$client" '#{pane_id}') || exit 0
case "$commands" in
    *'new-pane '*) ;;
    *) exec tmux -S "$socket_path" choose-tree -Zs -t "$target_pane" ;;
esac

popup_pane=$(tmux -S "$socket_path" new-pane -P -F '#{pane_id}' -t "$target_pane" \
    -x '70%' -y '60%' -X '15%' -Y '20%' \
    -s 'bg=colour237,fg=colour248' -S 'bg=default,fg=colour244' '') || exit 0

# Only the temporary selector is closed when its mode ends or loses focus.
cleanup="run-shell -b \"tmux -S #{q:socket_path} kill-pane -t $popup_pane 2>/dev/null || :\""
if ! tmux -S "$socket_path" set-hook -p -t "$popup_pane" 'pane-mode-changed[90]' \
    "if-shell -F '#{==:#{pane_in_mode},0}' '$cleanup'"; then
    tmux -S "$socket_path" kill-pane -t "$popup_pane" 2>/dev/null || :
    exit 0
fi
tmux -S "$socket_path" set-hook -p -t "$popup_pane" 'pane-focus-out[90]' "$cleanup"
if ! tmux -S "$socket_path" choose-tree -s -t "$popup_pane" -f "#{!=:#{pane_id},$popup_pane}"; then
    tmux -S "$socket_path" kill-pane -t "$popup_pane" 2>/dev/null || :
fi
