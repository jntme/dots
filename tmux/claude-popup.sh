#!/usr/bin/env bash
# Ctrl+Y: scratch Claude Code in a popup. Runs in its own hidden tmux session
# "_claude", so closing the popup (Ctrl+Y again) keeps the conversation alive.
# Sessions starting with "_" are hidden from the switcher and status bar.

if ! tmux has-session -t _claude 2>/dev/null; then
  tmux new-session -d -s _claude -c ~ claude
  tmux set -t _claude status off
fi
exec env -u TMUX tmux attach-session -t _claude
