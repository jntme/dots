#!/usr/bin/env bash
# Claude Code hook: records the session state on its tmux pane (@claude_state)
# for the status bar and the Ctrl+Space switcher, and sends a macOS
# notification when Claude needs input and the pane is not in view.
#
# States: working | waiting (permission/question) | done (turn finished) | idle

[ -n "$TMUX_PANE" ] || exit 0
input=$(cat)
event=$(jq -r '.hook_event_name // empty' <<<"$input")

case "$event" in
  SessionStart)
    # One tmux session per project: move this window to its project's session
    ~/.dots/tmux/claude-autosort.sh "$TMUX_PANE" "$(jq -r '.cwd // empty' <<<"$input")" 2>/dev/null
    state=idle ;;
  UserPromptSubmit|PostToolUse)
    state=working ;;
  PreToolUse)
    if [ "$(jq -r '.tool_name // empty' <<<"$input")" = AskUserQuestion ]; then
      state=waiting
    else
      state=working
    fi ;;
  Notification)
    case "$(jq -r '.notification_type // empty' <<<"$input")" in
      idle_prompt|auth_success) exit 0 ;;
    esac
    state=waiting ;;
  Stop|StopFailure)
    state=done ;;
  SessionEnd)
    tmux set -pu -t "$TMUX_PANE" @claude_state \; set -pu -t "$TMUX_PANE" @claude_session_id 2>/dev/null
    exit 0 ;;
  *)
    exit 0 ;;
esac

# @claude_session_id lets tmux-resurrect resume this exact conversation (claude-save-ids.sh)
session_id=$(jq -r '.session_id // empty' <<<"$input")
tmux set -p -t "$TMUX_PANE" @claude_state "$state" \; set -p -t "$TMUX_PANE" @claude_session_id "$session_id" 2>/dev/null

[ "$state" = waiting ] || [ "$state" = done ] || exit 0

# Pane visible = its session is attached and it is the active pane of the active window
visible=$(tmux display -p -t "$TMUX_PANE" '#{&&:#{session_attached},#{&&:#{window_active},#{pane_active}}}' 2>/dev/null)
[ "$visible" = 1 ] && exit 0

session=$(tmux display -p -t "$TMUX_PANE" '#{session_name}')
[[ $session == _* ]] && exit 0
topic=$(tmux display -p -t "$TMUX_PANE" '#{s/^[^ ]+ //:pane_title}')
if [ "$state" = waiting ]; then
  msg=$(jq -r '.message // empty' <<<"$input")
  [ -n "$msg" ] || msg="Wartet auf deine Eingabe"
else
  msg="Fertig"
fi

# Off on the Mac mini server tmux, the laptop notifies instead
[ "${CLAUDE_TMUX_NOTIFY:-1}" = 1 ] || exit 0

# Click: bring iTerm2 to the front and jump to this pane. One notification per
# pane (-group), so a newer one replaces the older.
jump="/opt/homebrew/bin/tmux switch-client -t '$TMUX_PANE' \\; select-window -t '$TMUX_PANE' \\; select-pane -t '$TMUX_PANE'"
/opt/homebrew/bin/terminal-notifier \
  -title "Claude Code · $session" -subtitle "$topic" -message "$msg" \
  -group "claude-$TMUX_PANE" -activate com.googlecode.iterm2 -execute "$jump" \
  >/dev/null 2>&1 &
exit 0
