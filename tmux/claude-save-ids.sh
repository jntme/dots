#!/usr/bin/env bash
# tmux-resurrect post-save hook: remembers which Claude Code conversation runs
# in which pane (session:window.pane -> session id), for claude-restore.sh.

dir=~/.local/share/tmux
mkdir -p "$dir"
tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index}	#{@claude_session_id}' |
  awk -F '\t' '$2 != ""' >"$dir/claude-sessions.tsv.tmp" &&
  mv "$dir/claude-sessions.tsv.tmp" "$dir/claude-sessions.tsv"
