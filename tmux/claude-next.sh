#!/usr/bin/env bash
# prefix+Space: jump to the next Claude Code pane that needs attention
# (✋ waiting first, then ✓ done), cycling past the current pane.
# Usage: claude-next.sh <client> <current pane id>

client=$1
current=$2

target=$(tmux list-panes -a -F '#{@claude_state} #{pane_id} #{session_name} #{window_id}' |
  awk -v cur="$current" '
    $3 ~ /^_/       { next }
    $1 == "waiting" { w[++nw] = $0 }
    $1 == "done"    { d[++nd] = $0 }
    END {
      for (i = 1; i <= nw; i++) all[++n] = w[i]
      for (i = 1; i <= nd; i++) all[++n] = d[i]
      # first candidate after the current pane, wrapping around
      for (i = 1; i <= n; i++) {
        split(all[i], f, " ")
        if (f[2] == cur) { start = i; break }
      }
      for (k = 1; k <= n; k++) {
        i = (start + k - 1) % n + 1
        split(all[i], f, " ")
        if (f[2] != cur) { print f[2], f[3], f[4]; exit }
      }
    }')

if [ -z "$target" ]; then
  tmux display-message -c "$client" 'Keine Claude-Session wartet auf dich'
  exit 0
fi

read -r pane session window <<<"$target"
tmux switch-client -c "$client" -t "$session"
tmux select-window -t "$window"
tmux select-pane -t "$pane"
