#!/bin/sh

# Query the IPv4 route without sending traffic to the destination.
network_field() {
    command -v jq >/dev/null 2>&1 || return 0
    network_key=$1
    network_os=$(uname -s 2>/dev/null) || return 0

    case "$network_os" in
        Linux)
            network_route=$(ip -j -4 route get 1.1.1.1 2>/dev/null) || return 0
            printf '%s\n' "$network_route" |
                jq -er --arg key "$network_key" \
                    '.[0][$key] | select(type == "string" and length > 0)' 2>/dev/null || :
            ;;
        Darwin)
            network_route=$(route -n get -inet 1.1.1.1 2>/dev/null) || return 0
            network_nic=$(printf '%s\n' "$network_route" |
                awk '$1 == "interface:" { print $2; exit }') || return 0
            [ -n "$network_nic" ] || return 0

            case "$network_key" in
                dev)
                    printf '%s\n' "$network_nic"
                    ;;
                prefsrc)
                    network_ip=$(ipconfig getifaddr "$network_nic" 2>/dev/null) || return 0
                    [ -n "$network_ip" ] || return 0
                    printf '%s\n' "$network_ip"
                    ;;
            esac
            ;;
    esac
}
