#!/usr/bin/env bash
# Runs Claude Code on a Claude server (Mac mini, see claude-hosts) for projects
# that live there. Called by the zsh function `claude` in ~/.dots/zshrc.
#   claude-remote.sh where <dir>          -> "<host or local><tab><reason>"
#   claude-remote.sh default <dir>        -> server the project moves to by default
#   claude-remote.sh hosts                -> names of all servers
#   claude-remote.sh run <dir> [args...]  -> start or attach the server session
#   claude-remote.sh poll                 -> refresh ~/.cache/claude-remote/sessions-<host>
#                                            (called in the background by claude-status.sh)
# The server is $CLAUDE_REMOTE_HOST (default mini).
#
# A project lives on a server if its root contains .claude-host (line
# host=<server>) or is listed in ~/.config/claude-remote/projects (one root
# per line, ~ allowed, optionally followed by the server; without it: mini).
# A local Claude session of the project always wins, so a project never runs
# in two places by accident.
#
# Server sessions run in the tmux server "claude" (the anchor) on the server,
# normally started in the graphical session (LaunchAgent) so it can use the
# keychain. Where Claude is logged in with a file (~/.claude/.credentials.json,
# login made over SSH, e.g. without a graphical login) and nobody is logged in graphically, this
# script starts the anchor over SSH instead.

HOST=${CLAUDE_REMOTE_HOST:-mini}
CONF=~/.config/claude-remote
HOSTS_FILE=~/.dots/tmux/claude-hosts

hosts() { awk '!/^#/ && NF { print $1 }' "$HOSTS_FILE"; }

# The server whose folder contains the project root, else the first one
default() {
  local root
  root=$(~/.dots/tmux/claude-project.sh "$1" | cut -f2)
  awk -v r="$root" -v home="$HOME" '
    /^#/ || !NF { next }
    first == "" { first = $1 }
    { d = $2; sub(/^~/, home, d); if (index(r "/", d "/") == 1) { print $1; found = 1; exit } }
    END { if (!found) print first }' "$HOSTS_FILE"
}

where() {
  local dir=$1 project root host
  IFS=$'\t' read -r project root < <(~/.dots/tmux/claude-project.sh "$dir")

  if [ -n "$TMUX" ] && tmux list-panes -a -F '#{pane_id}	#{@claude_project}	#{?#{@claude_host},1,0}' |
      awk -F '\t' -v p="$project" -v me="$TMUX_PANE" '$1 != me && $2 == p && $3 == 0 { f = 1 } END { exit !f }'; then
    printf 'local\tlocal session running\n'
  elif [ -f "$root/.claude-host" ]; then
    host=$(sed -n 's/^host=//p' "$root/.claude-host" | head -1)
    printf '%s\t.claude-host\n' "${host:-$HOST}"
  elif host=$(sed "s|^~|$HOME|" "$CONF/projects" 2>/dev/null | awk -v r="$root" '$1 == r { print ($2 != "" ? $2 : "mini"); exit }') && [ -n "$host" ]; then
    printf '%s\tprojects\n' "$host"
  else
    printf 'local\t-\n'
  fi
}

# Remove the server marks from a window (pink tab, state, title)
unmark() {
  local option
  for option in @claude_host @claude_remote_session @claude_state @claude_rc @claude_done_seen @claude_title; do
    tmux set -wu -t "$1" "$option" 2>/dev/null
  done
  tmux set -pu -t "$TMUX_PANE" @claude_project 2>/dev/null
}

run() {
  local dir=$1 project root addr state inner remote rc window
  shift
  IFS=$'\t' read -r project root < <(~/.dots/tmux/claude-project.sh "$dir")
  addr=$(ssh -G "$HOST" | awk '/^hostname /{ print $2 }')

  if ! ssh -O check "$HOST" 2>/dev/null && ! nc -z -G 2 "$addr" 22 2>/dev/null; then
    echo "⚠ $HOST not reachable ($addr). Right network or VPN connected?" >&2
    return 1
  fi
  state=$(ssh -n -o BatchMode=yes -o ConnectTimeout=5 "$HOST" \
    "tmux -L claude run-shell true 2>/dev/null && echo anker; test -d $(printf %q "$dir") && echo ordner; test -f ~/.claude/.credentials.json && echo datei; ~/.dots/tmux/claude-project.sh $(printf %q "$dir") | sed -n '1s/\t.*//; 1s/^/projekt=/p'" 2>/dev/null)
  if [ $? -ne 0 ] && [ -z "$state" ]; then
    echo "⚠ SSH login to $HOST failed. After a restart run $HOST-unlock first." >&2
    return 1
  fi
  if [[ $state != *anker* && $state == *datei* ]]; then
    echo "Starting the Claude tmux on $HOST (login from file) …" >&2
    ssh -n "$HOST" 'tmux -L claude -f ~/.dots/tmux/server.conf start-server' && state="$state anker"
  fi
  if [[ $state != *anker* ]]; then
    echo "⚠ The Claude tmux is not running on $HOST: nobody is logged in graphically." >&2
    echo "  Log in once via Screen Sharing: open vnc://$addr" >&2
    return 1
  fi
  if [[ $state != *ordner* ]]; then
    echo "⚠ $dir does not exist on $HOST. Move it with claude-move $HOST or clone it there." >&2
    return 1
  fi

  # The server decides the name: a subfolder with its own CLAUDE.md (agent) is
  # its own session there, and the local folder may be empty (claude-move)
  [[ $state =~ projekt=([^$'\n']+) ]] && project=${BASH_REMATCH[1]}

  # Two levels of quoting: the remote shell runs tmux, tmux runs the command
  inner=$(printf '%q ' claude --remote-control "$project" "$@")
  remote=$(printf '%q ' tmux -L claude new-session -A -s "$project" -c "$dir" "$inner")

  if [ -n "$TMUX" ]; then
    ~/.dots/tmux/claude-autosort.sh "$TMUX_PANE" "$dir" "$project"
    # Window options, so the tab shows the server session whichever pane is active.
    # By window id: once the pane is closed, its id no longer finds the window.
    window=$(tmux display -p -t "$TMUX_PANE" '#{window_id}')
    tmux set -w -t "$window" @claude_host "$HOST" \; set -w -t "$window" @claude_remote_session "$project"
  fi
  # In the background with an explicit stdin (it stays the terminal): a trap
  # only interrupts `wait`, not a foreground command. Closing the pane (Ctrl+W)
  # sends SIGHUP, but ssh over the shared connection (ControlMaster) would keep
  # running without a terminal: end it and unmark the window, which lives on
  # when it has other panes.
  ssh -t "$HOST" "$remote" <&0 &
  pid=$!
  trap 'kill $pid 2>/dev/null; [ -n "$TMUX" ] && unmark "$window"; exit 129' HUP TERM
  wait $pid
  rc=$?
  if [ -n "$TMUX" ]; then
    trap - HUP TERM
    unmark "$window"
  fi
  return $rc
}

# One line per server session: "<tmux session> <state> <remote control 0/1> <title> <folder>".
# Claude keeps ~/.claude/sessions/<pid>.json, with bridgeSessionId while
# Remote Control is connected; the session's pane runs claude directly.
POLL='tmux -L claude list-panes -a -F "#{session_name}	#{pane_pid}	#{?#{@claude_state},#{@claude_state},idle}	#{pane_title}	#{pane_current_path}" 2>/dev/null |
  while IFS="	" read -r session pid state title dir; do
    rc=$(jq -r "if .bridgeSessionId then 1 else 0 end" ~/.claude/sessions/$pid.json 2>/dev/null)
    printf "%s\t%s\t%s\t%s\t%s\n" "$session" "$state" "${rc:-0}" "$title" "$dir"
  done'

poll() {
  local cache=~/.cache/claude-remote out
  mkdir -p "$cache"
  find "$cache/poll-$HOST.lock" -maxdepth 0 -mmin +1 -exec rmdir {} \; 2>/dev/null  # stale lock
  mkdir "$cache/poll-$HOST.lock" 2>/dev/null || return 0                             # one poll at a time
  trap "rmdir $(printf %q "$cache/poll-$HOST.lock")" EXIT
  if out=$(ssh -n -o BatchMode=yes -o ConnectTimeout=3 "$HOST" "bash -c $(printf %q "$POLL")" 2>/dev/null); then
    printf '%s\n' "$out" >"$cache/sessions-$HOST.tmp" && mv "$cache/sessions-$HOST.tmp" "$cache/sessions-$HOST"
  fi
}

cmd=$1
shift
case $cmd in
  where) where "$@" ;;
  default) default "$@" ;;
  hosts) hosts ;;
  run) run "$@" ;;
  poll) poll ;;
  *) echo "Usage: claude-remote.sh where <dir> | default <dir> | hosts | run <dir> [args...] | poll" >&2; exit 2 ;;
esac
