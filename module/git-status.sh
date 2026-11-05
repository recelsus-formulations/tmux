#!/bin/sh

set -eu

tmux_style=0
details=0
case "${1:-}" in
    --tmux)
        tmux_style=1
        shift
        ;;
    --details)
        details=1
        shift
        ;;
esac

empty_status() {
    if [ "$tmux_style" -eq 1 ]; then
        printf '%s\n' '-'
    fi
}

command -v git >/dev/null 2>&1 || {
    empty_status
    exit 0
}
target_path=${1:-.}
git_status=$(git --no-optional-locks -C "$target_path" status \
    --porcelain=v2 --branch --untracked-files=normal 2>/dev/null) || {
    empty_status
    exit 0
}

printf '%s\n' "$git_status" | awk -v tmux_style="$tmux_style" -v details="$details" '
    /^# branch.head / { branch = $3 }
    /^# branch.oid / { commit = $3 }
    /^# branch.upstream / { upstream = $3 }
    /^# branch.ab / {
        has_upstream_counts = 1
        ahead = substr($3, 2) + 0
        behind = substr($4, 2) + 0
    }
    /^[12?u] / { dirty = 1 }
    /^[12] / {
        if (substr($2, 1, 1) != ".") {
            staged++
        }
        if (substr($2, 2, 1) != ".") {
            unstaged++
        }
    }
    /^\? / { untracked++ }
    /^u / { conflicts++ }
    END {
        if (branch == "") {
            exit
        }
        if (branch == "(detached)") {
            branch = "@" substr(commit, 1, 7)
        }
        if (details) {
            printf "Branch: %s\n", branch
            printf "Commit: %s\n", (commit == "(initial)" ? "No commits yet" : substr(commit, 1, 12))
            printf "Upstream: %s\n", (upstream == "" ? "Not configured" : upstream)
            printf "Ahead: %s\n", (has_upstream_counts ? sprintf("%d", ahead) : "-")
            printf "Behind: %s\n", (has_upstream_counts ? sprintf("%d", behind) : "-")
            printf "Staged files: %d\n", staged
            printf "Unstaged files: %d\n", unstaged
            printf "Untracked entries: %d\n", untracked
            printf "Conflicts: %d\n", conflicts
            exit
        }
        if (tmux_style) {
            gsub(/#/, "##", branch)
        }
        printf "%s%s%s\n", branch, dirty ? "*" : "", conflicts ? "!" : ""
    }
'
