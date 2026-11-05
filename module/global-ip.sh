#!/bin/sh

set -eu

command -v curl >/dev/null 2>&1 || exit 0
public_ip=$(curl -q -4 -fsS --connect-timeout 1 --max-time 2 https://api.ipify.org 2>/dev/null) || exit 0

# Only display a plain IPv4 address, including when a proxy returns other content.
printf '%s\n' "$public_ip" | awk -F . '
    NR != 1 { invalid = 1 }
    {
        if (NF != 4) {
            invalid = 1
        }
        for (i = 1; i <= NF; i++) {
            if ($i !~ /^[0-9]+$/ || length($i) > 3 || $i + 0 > 255) {
                invalid = 1
            }
        }
    }
    END {
        if (!invalid && NR == 1) {
            print
        }
    }
'
