#!/usr/bin/env bash
# Moves the window of a Claude Code pane into the tmux session of its project
# (one session per project), creating the session if needed. Clients that are
# looking at the window follow it. Called from claude-hook.sh on SessionStart.
# Usage: claude-autosort.sh <pane id> <folder Claude was started in> [project]
# (project: name decided elsewhere, e.g. by the server for a remote session)
#
# Set CLAUDE_TMUX_AUTOSORT=0 to disable (e.g. on a server whose tmux is
# managed by the remote wrapper).

[ "${CLAUDE_TMUX_AUTOSORT:-1}" = 1 ] || exit 0
pane=$1
dir=$2

IFS=$'\t' read -r project root < <(~/.dots/tmux/claude-project.sh "$dir")
[ -n "$3" ] && project=$3
tmux set -p -t "$pane" @claude_project "$project"

IFS=$'\t' read -r session window panes < <(tmux display -p -t "$pane" '#{session_name}	#{window_id}	#{window_panes}')
[ "$session" = "$project" ] && exit 0
[[ $session == _* ]] && exit 0   # hidden helper sessions (_claude popup)
[ "$panes" = 1 ] || exit 0       # split window: other panes may belong elsewhere

# Clients currently showing this window should follow it
followers=$(tmux list-clients -F '#{client_name}	#{session_name}	#{window_id}' |
  awk -F '\t' -v s="$session" -v w="$window" '$2 == s && $3 == w { print $1 }')

if tmux has-session -t "=$project" 2>/dev/null; then
  tmux move-window -s "$window" -t "=$project:"
else
  placeholder=$(tmux new-session -d -P -F '#{window_id}' -s "$project" -c "$root")
  tmux move-window -s "$window" -t "=$project:"
  tmux kill-window -t "$placeholder"
fi

for client in $followers; do
  tmux switch-client -c "$client" -t "=$project"
  tmux select-window -t "$window"
done
