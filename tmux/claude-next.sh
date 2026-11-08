#!/usr/bin/env bash
# prefix+Space: jump to the next Claude Code pane that needs attention
# (✋ waiting first, then ✓ done), cycling past the current pane. Sessions
# on a Claude server that wait but have no window here come after the local
# waiting ones and get connected (claude-attach-remote.sh).
# Usage: claude-next.sh <client> <current pane id>

client=$1
current=$2

# Waiting server sessions as "waiting srv:<host>:<session> - -" (fresh poll caches only)
now=$(date +%s)
target=$( {
  tmux list-panes -a -F '#{@claude_state} #{pane_id} #{session_name} #{window_id}'
  for f in ~/.cache/claude-remote/sessions-*; do
    [ -f "$f" ] && [ $(( now - $(stat -f %m "$f") )) -lt 30 ] &&
      awk -F '\t' -v h="${f##*/sessions-}" '$2 == "waiting" && $1 !~ /^_/ { print "waiting srv:" h ":" $1 " - -" }' "$f"
  done
} | CONNECTED=$(tmux list-windows -a -F '#{@claude_host}:#{@claude_remote_session}' | grep -v '^:$') \
  awk -v cur="$current" '
    BEGIN { nc = split(ENVIRON["CONNECTED"], c, "\n"); for (i = 1; i <= nc; i++) conn["srv:" c[i]] = 1 }
    $2 in conn      { next }   # shown by its connected window
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
if [[ $pane == srv:* ]]; then
  IFS=: read -r _ host name <<<"$pane"
  exec ~/.dots/tmux/claude-attach-remote.sh "$client" "$host" "$name"
fi
tmux switch-client -c "$client" -t "$session"
tmux select-window -t "$window"
tmux select-pane -t "$pane"
