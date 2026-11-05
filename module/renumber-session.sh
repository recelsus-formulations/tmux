#!/bin/sh

set -eu

command -v tmux >/dev/null 2>&1 || exit 0
socket_path=${1:-}
if [ -z "$socket_path" ]; then
    socket_path=$(tmux display-message -p '#{socket_path}' 2>/dev/null) || exit 0
fi

# Serialise hooks on this server without affecting another tmux socket.
tmux -S "$socket_path" wait-for -L renumber_sessions 2>/dev/null || exit 0
trap 'tmux -S "$socket_path" wait-for -U renumber_sessions 2>/dev/null || :' 0
trap 'exit 1' HUP INT TERM

sessions=$(tmux -S "$socket_path" list-sessions -F '#{session_id} #{session_name}' 2>/dev/null) || exit 0
sorted_sessions=$(printf '%s\n' "$sessions" | LC_ALL=C sort -k2,2n) || exit 0
new_number=0
while IFS=' ' read -r session_id session_name; do
    case "$session_name" in
        '' | *[!0-9]*) continue ;;
        0) ;;
        0*) continue ;;
    esac
    if [ "$session_name" != "$new_number" ]; then
        if ! tmux -S "$socket_path" rename-session -t "$session_id" "$new_number" 2>/dev/null; then
            continue
        fi
    fi
    new_number=$((new_number + 1))
done <<EOF
$sorted_sessions
EOF
