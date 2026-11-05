#!/bin/sh

set -eu

command -v tmux >/dev/null 2>&1 || exit 0
client=${1:-}
menu_x=${2:-0}
target_path=${3:-.}
[ -n "$client" ] || exit 0
case "$menu_x" in
    R | C) ;;
    '' | *[!0-9]*) menu_x=0 ;;
esac
script_dir=$(CDPATH='' cd -P "$(dirname "$0")" && pwd)
details=$(sh "$script_dir/git-status.sh" --details "$target_path") || details=''
if [ -z "$details" ]; then
    if command -v git >/dev/null 2>&1; then
        details='No Git worktree available'
    else
        details='Git is not installed'
    fi
fi

set -- display-menu -O -M -c "$client" -x "$menu_x" -y S \
    -T 'Git' -s 'bg=colour237,fg=colour255' -S 'fg=colour244' --
while IFS= read -r line; do
    # Disabled items keep this menu read-only. Escape tmux format markers.
    label=$(printf '%s' "$line" | sed 's/#/##/g')
    set -- "$@" "-$label" '' ''
done <<EOF
$details
EOF
tmux "$@"
