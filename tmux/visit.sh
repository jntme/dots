#!/usr/bin/env bash
# tmux hook: remember when a window was shown (@visited), for the most-recent
# order in the switcher and Ctrl+Tab.
# Usage: visit.sh <window id>

tmux set -w -t "$1" @visited "$(date +%s)"
