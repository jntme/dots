#!/usr/bin/env bash
# Status-bar segment: lists projects where Claude needs attention, e.g.
# "✋ shop  ✋ blog". Called with the pane the client is looking at, which
# counts as seen: a "done" state there is reset to idle.

current=$1
if [ -n "$current" ] && [ "$(tmux display -p -t "$current" '#{?#{@claude_host},,#{@claude_state}}' 2>/dev/null)" = done ]; then
  tmux set -p -t "$current" @claude_state idle
  /opt/homebrew/bin/terminal-notifier -remove "claude-$current" >/dev/null 2>&1 &
fi

# Claude Code keeps ~/.claude/sessions/<pid>.json per running session, with its
# tmux pane, the folder it was started in (cwd) and, while Remote Control is
# connected, a bridgeSessionId. Mirror that onto the panes:
#   @claude_project = project of the start folder (set by claude-autosort.sh on
#                     SessionStart; filled in here for older sessions)
#   @claude_rc      = Remote Control on (📡)
# Fields are never empty (rc is 0/1): read with IFS=tab would merge empty fields.
sessions=$(jq -r 'select(.tmux) | [.pid, (.tmux | sub(".*\\."; "")), (if .bridgeSessionId then 1 else 0 end), .cwd] | @tsv' \
  ~/.claude/sessions/*.json 2>/dev/null |
  while IFS=$'\t' read -r pid pane rc cwd; do
    kill -0 "$pid" 2>/dev/null && printf '%s\t%s\t%s\n' "$pane" "$rc" "$cwd"
  done)

# Other panes get @dir_project = project of their current folder, recomputed
# only when the folder changes (@dir_project_for). Empty field last on purpose.
# Panes in a window connected to a server session (@claude_host,
# claude-remote.sh) are handled below and skipped here.
tmux list-panes -a -F '#{pane_id}	#{?#{@claude_rc},1,0}	#{?#{@claude_project},1,0}	#{?#{@claude_host},1,0}	#{pane_current_path}	#{@dir_project_for}' |
while IFS=$'\t' read -r pane rc has_project remote path dir_for; do
  [ "$remote" = 1 ] && continue
  if [ "$path" != "$dir_for" ]; then
    tmux set -p -t "$pane" @dir_project "$(~/.dots/tmux/claude-project.sh "$path" | cut -f1)" \; \
      set -p -t "$pane" @dir_project_for "$path"
  fi

  line=$(awk -F '\t' -v p="$pane" '$1 == p' <<<"$sessions")
  if [ -n "$line" ]; then
    IFS=$'\t' read -r _ want_rc cwd <<<"$line"
  else
    want_rc=0 cwd=
  fi

  if [ "$want_rc" != "$rc" ]; then
    if [ "$want_rc" = 1 ]; then tmux set -p -t "$pane" @claude_rc 1; else tmux set -pu -t "$pane" @claude_rc; fi
  fi
  if [ -n "$cwd" ] && [ "$has_project" = 0 ]; then
    tmux set -p -t "$pane" @claude_project "$(~/.dots/tmux/claude-project.sh "$cwd" | cut -f1)"
  elif [ -z "$cwd" ] && [ "$has_project" = 1 ]; then
    tmux set -pu -t "$pane" @claude_project
  fi
done

# Windows connected to a server session (window option @claude_host, set by
# claude-remote.sh): state, Remote Control and title come from the server and
# are kept as window options, so the tab shows them whichever pane is active.
# claude-remote.sh poll refreshes ~/.cache/claude-remote/sessions-<host> in the
# background, this only reads it, so an unreachable server never blocks.
now=$(date +%s)
# Servers with moved projects (~/.config/claude-remote/projects) are polled even
# without a connected window, so the switcher and ✋ know their sessions
for host in $(awk '!/^#/ && NF { print ($2 != "" ? $2 : "mini") }' ~/.config/claude-remote/projects 2>/dev/null | sort -u); do
  [ $(( now - $(stat -f %m ~/.cache/claude-remote/sessions-$host 2>/dev/null || echo 0) )) -ge 4 ] &&
    (CLAUDE_REMOTE_HOST=$host ~/.dots/tmux/claude-remote.sh poll >/dev/null 2>&1 &)
done
current_window=$(tmux display -p -t "$current" '#{window_id}' 2>/dev/null)
tmux list-windows -a -F '#{window_id}	#{@claude_host}	#{?#{@claude_remote_session},#{@claude_remote_session},#{session_name}}	#{?#{@claude_state},#{@claude_state},-}	#{?#{@claude_rc},1,0}	#{?#{@claude_done_seen},1,0}	#{session_name}	#{@claude_title}' |
awk -F '\t' '$2 != ""' |
while IFS=$'\t' read -r window host project old_state old_rc seen session old_title; do
  cache=~/.cache/claude-remote/sessions-$host
  age=$(( now - $(stat -f %m "$cache" 2>/dev/null || echo 0) ))
  [ "$age" -ge 4 ] && (CLAUDE_REMOTE_HOST=$host ~/.dots/tmux/claude-remote.sh poll >/dev/null 2>&1 &)

  state=- rc=0 title=
  if [ "$age" -lt 30 ]; then   # older = server unreachable: show no state
    IFS=$'\t' read -r _ state rc title < <(awk -F '\t' -v p="$project" '$1 == p' "$cache")
    state=${state:--} rc=${rc:-0}
  fi
  # "done" counts as seen once you looked at the window, as for local sessions
  if [ "$state" = done ]; then
    if [ "$window" = "$current_window" ] || [ "$seen" = 1 ]; then
      state=idle
      [ "$seen" = 1 ] || tmux set -w -t "$window" @claude_done_seen 1
    fi
  elif [ "$seen" = 1 ]; then
    tmux set -wu -t "$window" @claude_done_seen
  fi

  if [ "$state" != "$old_state" ]; then
    if [ "$state" = - ]; then tmux set -wu -t "$window" @claude_state; else tmux set -w -t "$window" @claude_state "$state"; fi
    # Notify like claude-hook.sh does for local sessions (the server never notifies)
    if { [ "$state" = waiting ] || [ "$state" = done ]; } && [ "$window" != "$current_window" ]; then
      [ "$state" = waiting ] && msg="Wartet auf deine Eingabe" || msg="Fertig"
      jump="/opt/homebrew/bin/tmux switch-client -t '$window' \; select-window -t '$window'"
      /opt/homebrew/bin/terminal-notifier -title "Claude Code · $session ($host)" -subtitle "${title#* }" -message "$msg" \
        -group "claude-$window" -activate com.googlecode.iterm2 -execute "$jump" >/dev/null 2>&1 &
    fi
  fi
  if [ "$rc" != "$old_rc" ]; then
    if [ "$rc" = 1 ]; then tmux set -w -t "$window" @claude_rc 1; else tmux set -wu -t "$window" @claude_rc; fi
  fi
  [ -n "$title" ] && [ "$title" != "$old_title" ] && tmux set -w -t "$window" @claude_title "$title"
done

# Server sessions without a connected window come from the poll caches (< 30 s old)
{
  tmux list-panes -a -F '#{pane_id} #{session_name} #{@claude_state} #{?#{@claude_project},#{@claude_project},#{session_name}}' 2>/dev/null
  for f in ~/.cache/claude-remote/sessions-*; do
    [ -f "$f" ] && [ $(( now - $(stat -f %m "$f") )) -lt 30 ] && awk -F '\t' '{ print "- srv " $2 " " $1 }' "$f"
  done
} |
  awk -v cur="$current" '
    $1 == cur { here[$4] = 1; next }   # the project you are looking at needs no hint
    $2 ~ /^_/ { next }
    $3 == "waiting" && !($4 in seen) { seen[$4] = 1; order[++n] = $4 }
    END {
      for (i = 1; i <= n; i++) if (!(order[i] in here)) w = w " ✋ " order[i]
      if (w != "") printf "#[fg=colour214,bold]%s #[default]", w
    }'
