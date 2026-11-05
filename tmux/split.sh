#!/usr/bin/env bash
# Splits the pane; in a window of a remote Claude session (@claude_host) or in
# a pane running ssh the new pane logs into the same server, in the same folder
# (same paths on laptop and servers). Otherwise a plain local split.
#   split.sh <pane> <-h|-v> [--local]
pane=$1 dir=$2
path=$(tmux display -p -t "$pane" '#{pane_current_path}')

host=
if [ "${3:-}" != --local ]; then
  host=$(tmux display -p -t "$pane" '#{@claude_host}')
  if [ -z "$host" ]; then
    # ssh as the pane's process or as a child of its shell; the host is the
    # first argument that is neither an option nor the value of one
    pid=$(tmux display -p -t "$pane" '#{pane_pid}')
    ssh_pid=$( { ps -o pid=,comm= -p "$pid"; pgrep -P "$pid" | xargs -I{} ps -o pid=,comm= -p {}; } 2>/dev/null |
      awk '$2 == "ssh" { print $1; exit }')
    [ -n "$ssh_pid" ] && host=$(ps -o args= -p "$ssh_pid" | awk '{
      for (i = 2; i <= NF; i++) {
        if ($i ~ /^-[BbcDEeFIiJLlmOoPpRSWw]$/) { i++; continue }
        if ($i ~ /^-/) continue
        print $i; exit
      } }')
  fi
fi

if [ -z "$host" ]; then
  exec tmux split-window "$dir" -t "$pane" -c "$path"
fi

remote="cd $(printf %q "$path") 2>/dev/null || echo '${path/#$HOME/~} does not exist on $host'; exec \$SHELL -l"
# Unreachable server: say so and keep a local shell instead of a closing pane
exec tmux split-window "$dir" -t "$pane" -c "$path" \
  "ssh -t $(printf %q "$host") $(printf %q "$remote") || { echo '⚠ ssh $host failed, local shell'; exec \$SHELL -l; }"
