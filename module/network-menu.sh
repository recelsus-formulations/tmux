#!/bin/sh

set -eu

command -v tmux >/dev/null 2>&1 || exit 0
client=${1:-}
menu_x=${2:-0}
[ -n "$client" ] || exit 0
case "$menu_x" in
    R | C) ;;
    '' | *[!0-9]*) menu_x=0 ;;
esac
script_dir=$(CDPATH='' cd -P "$(dirname "$0")" && pwd)

host=$(tmux display-message -p -c "$client" '#H') || exit 0
nic=$(sh "$script_dir/nic.sh") || nic=''
local_ip=$(sh "$script_dir/local-ip.sh") || local_ip=''
global_ip=$(sh "$script_dir/global-ip.sh") || global_ip=''

# Menu commands are parsed by tmux after format expansion.
quote_tmux() {
    printf "'"
    printf '%s' "$1" | sed -e 's/#/##/g' -e "s/'/'\\\\''/g"
    printf "'"
}

copy_command() {
    printf 'set-buffer -w -t %s -- %s' "$(quote_tmux "$client")" "$(quote_tmux "$1")"
}

menu_label() {
    if [ -z "$2" ]; then
        printf -- '-%-11s -' "$1"
    else
        printf '%-11s %s' "$1" "$2" | sed 's/#/##/g'
    fi
}

all_info=$(printf 'Host: %s\nNIC: %s\nLocal IP: %s\nGlobal IP: %s' \
    "${host:--}" "${nic:--}" "${local_ip:--}" "${global_ip:--}")

tmux display-menu -O -M -c "$client" -x "$menu_x" -y S \
    -T 'Network (click to copy)' \
    -s 'bg=colour237,fg=colour248' \
    -H 'bg=colour239,fg=colour255' \
    -S 'fg=colour244' \
    "$(menu_label Host "$host")" '' "$(copy_command "$host")" \
    "$(menu_label NIC "$nic")" '' "$(copy_command "$nic")" \
    "$(menu_label 'Local IP' "$local_ip")" '' "$(copy_command "$local_ip")" \
    "$(menu_label 'Global IP' "$global_ip")" '' "$(copy_command "$global_ip")" \
    '' \
    'Copy all' '' "$(copy_command "$all_info")"
