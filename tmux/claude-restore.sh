#!/usr/bin/env bash
# Started by tmux-resurrect in panes that ran Claude Code: resumes the exact
# conversation of this pane (saved by claude-save-ids.sh), or else the most
# recent one in this directory.

key=$(tmux display -p -t "$TMUX_PANE" '#{session_name}:#{window_index}.#{pane_index}')
id=$(awk -F '\t' -v k="$key" '$1 == k { print $2 }' ~/.local/share/tmux/claude-sessions.tsv 2>/dev/null)

if [ -n "$id" ]; then
  claude --resume "$id"
else
  claude --continue
fi
