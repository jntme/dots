#!/usr/bin/env bash
# Shows a session on a Claude server in the local tmux, also one that `claude`
# in a folder would not reach (e.g. a second session of a project started on
# the server). Selects the window already connected to it; otherwise connects
# the given window when it only runs a shell, or opens a new window in the
# local session of that name. Used by the switcher (Enter) and claude-next.sh.
# Usage: claude-attach-remote.sh <client or ""> <host> <server session> [window]

client=$1 host=$2 name=$3 window=$4
switch() { tmux switch-client ${client:+-c "$client"} -t "$1"; tmux select-window -t "$2"; }

existing=$(tmux list-windows -a -F '#{window_id} #{session_name} #{@claude_host} #{@claude_remote_session}' |
  awk -v h="$host" -v n="$name" '$3 == h && $4 == n { print $1, $2; exit }')
if [ -n "$existing" ]; then
  read -r w s <<<"$existing"
  switch "$s" "$w"
  exit 0
fi

# Folder the session runs in on the server (claude-remote.sh poll); same path
# here, created when missing (the local folder of a moved project is empty)
dir=$(awk -F '\t' -v n="$name" '$1 == n { print $5; exit }' ~/.cache/claude-remote/sessions-"$host" 2>/dev/null)
[ -n "$dir" ] || dir=$HOME
case $dir in "$HOME"/*) mkdir -p "$dir" ;; esac
[ -d "$dir" ] || dir=$HOME

if [ -n "$window" ] && [[ $(tmux display -p -t "$window" '#{pane_current_command}' 2>/dev/null) =~ ^-?(zsh|bash|sh)$ ]]; then
  tmux send-keys -t "$window" C-u " cd $(printf %q "$dir")" Enter
else
  if tmux has-session -t "=$name" 2>/dev/null; then
    window=$(tmux new-window -d -P -F '#{window_id}' -t "=$name:" -c "$dir")
  else
    window=$(tmux new-session -d -P -F '#{window_id}' -s "$name" -c "$dir")
  fi
fi
tmux send-keys -t "$window" " CLAUDE_REMOTE_HOST=$(printf %q "$host") CLAUDE_REMOTE_SESSION=$(printf %q "$name") ~/.dots/tmux/claude-remote.sh run $(printf %q "$dir")" Enter
switch "$(tmux display -p -t "$window" '#{session_name}')" "$window"
