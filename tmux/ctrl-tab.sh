#!/usr/bin/env bash
# Ctrl+Tab: jump to the most recently visited window of another project, so
# pressing it again toggles back. Further back: Ctrl+Space (sorted by recency).
# Usage: ctrl-tab.sh <client>

client=$1
current=$(tmux display -p -c "$client" '#{E:@project-name}')
target=$(tmux list-windows -a -F '#{?#{@visited},#{@visited},0}	#{window_id}	#{session_name}	#{E:@project-name}' |
  awk -F '\t' -v cur="$current" '$3 !~ /^_/ && $4 != cur' | sort -t $'\t' -k1,1nr | head -1)
[ -n "$target" ] || exit 0

IFS=$'\t' read -r _ window session _ <<<"$target"
tmux switch-client -c "$client" -t "$session" \; select-window -t "$window"
