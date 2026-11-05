#!/usr/bin/env bash
# Ctrl+Space project switcher (runs inside a tmux popup).
# Lists one line per project (the window that needs you most, "+N" = more
# windows; Ctrl+A shows all windows), followed by project folders that have no
# session yet. Enter jumps there (creating the session if needed), Ctrl+X
# closes the selected window.

PROJECT_ROOTS=(~/Claude)

# Raw rows: target <tab> session <tab> kind <tab> state <tab> text <tab> remote control <tab> project <tab> host <tab> more windows
# host = server the window is connected to (@claude_host, claude-remote.sh), empty when local
# Sessions on a server (~/.cache/claude-remote/sessions-<host>, claude-remote.sh
# poll) also show for projects whose window is not connected (e.g. only a shell
# is open there) or that have no window at all.
# Project names come from claude-status.sh (@claude_project: where Claude was
# started, @dir_project: current folder; both the top folder of the project).
# Order: most recently visited first (@visited, set by tmux hooks), the current
# project last - so Ctrl+Space, Enter goes back to the previous project.
# Usage: rows [all]  - without "all" only the most important window per project
rows() {
  local windows current f
  current=$(tmux display -p '#{E:@project-name}')
  # "<project> <host> <state> <remote control> <title>" of fresh server caches
  export REMOTE
  REMOTE=$(for f in ~/.cache/claude-remote/sessions-*; do
    [ -f "$f" ] && [ $(( $(date +%s) - $(stat -f %m "$f") )) -lt 30 ] &&
      awk -F '\t' -v h="${f##*/sessions-}" '{ print $1 "\t" h "\t" $2 "\t" $3 "\t" $4 }' "$f"
  done)
  windows=$(tmux list-windows -a -F '#{window_id}	#{session_name}	#{@claude_state}	#{pane_current_command}	#{pane_title}	#{E:@project-name}	#{?#{@claude_rc},1,}	#{window_active}	#{?#{@visited},#{@visited},0}	#{@claude_host}	#{@claude_title}' |
    awk -F '\t' -v all="$1" -v cur="$current" '
      BEGIN {
        n = split(ENVIRON["REMOTE"], r, "\n")
        for (i = 1; i <= n; i++) if (split(r[i], f, "\t") >= 3) { rhost[f[1]] = f[2]; rstate[f[1]] = f[3]; rrc[f[1]] = (f[4] == 1) ? 1 : ""; rtitle[f[1]] = f[5] }
      }
      $2 ~ /^_/ { next }  # hidden helper sessions (e.g. _claude popup)
      {
        claude = ($3 != "" || $4 ~ /^[0-9]+\.[0-9]+\.[0-9]+$/ || $10 != "")
        host = $10; rc = $7; title = $11; rs = ""; kind = "win"
        # no Claude in this window, but the project has a session on a server
        if (!claude && all != "all" && ($6 in rhost)) { claude = 1; host = rhost[$6]; rc = rrc[$6]; title = rtitle[$6]; rs = rstate[$6]; kind = "srv" }
        state = ($3 != "") ? $3 : (rs != "") ? rs : (host != "") ? "remote" : (claude ? "idle" : "")
        text = (host != "" && title != "") ? title : $5   # server session: its title, whichever pane is active
        if (claude) sub(/^[^ ]+ /, "", text)
        else        text = $4
        row = $1 "\t" $2 "\t" kind "\t" state "\t" text "\t" rc "\t" $6 "\t" host
        if (all == "all") { print ($6 == cur) "\t" $9 "\t" row "\t0"; next }

        # keep the window that needs attention most: waiting > done > working > active
        prio = (state == "waiting") ? 4 : (state == "done") ? 3 : (state == "working") ? 2 : ($8 == 1) ? 1 : 0
        count[$6]++
        if ($9 > visited[$6]) visited[$6] = $9
        if (!($6 in best) || prio > bestprio[$6]) { best[$6] = row; bestprio[$6] = prio }
      }
      END { for (p in best) print (p == cur) "\t" visited[p] "\t" best[p] "\t" (count[p] - 1) }' |
    sort -s -t $'\t' -k1,1n -k2,2nr | cut -f3-)
  [ -n "$windows" ] && printf '%s\n' "$windows"

  # Project folders without an open window, most used first (one awk pass, no
  # per-folder subprocesses - the popup should appear instantly)
  local root
  for root in "${PROJECT_ROOTS[@]}"; do printf '%s\n' "$root"/*/; done |
    OPEN=$( { cut -f7 <<<"$windows"; tmux list-sessions -F '#{session_name}'; } ) \
    awk -v home="$HOME" -v now="$(date +%s)" -v z="$HOME/.z" '
      BEGIN {
        # open projects come via the environment (awk -v cannot hold newlines)
        n = split(ENVIRON["OPEN"], o, "\n"); for (i = 1; i <= n; i++) isopen[o[i]] = 1
        n = split(ENVIRON["REMOTE"], r, "\n")
        for (i = 1; i <= n; i++) if (split(r[i], f, "\t") >= 3) { rhost[f[1]] = f[2]; rstate[f[1]] = f[3]; rrc[f[1]] = (f[4] == 1) ? 1 : ""; rtitle[f[1]] = f[5] }
        # z database (path|rank|time) -> frecency score per path
        while ((getline line < z) > 0) {
          split(line, f, "|"); age = now - f[3]
          score[f[1]] = (age < 3600) ? f[2] * 4 : (age < 86400) ? f[2] * 2 : (age < 604800) ? f[2] / 2 : f[2] / 4
        }
      }
      {
        dir = $0; sub(/\/$/, "", dir)
        name = dir; sub(/.*\//, "", name); sub(/^\./, "", name); gsub(/[.:]/, "_", name)  # as claude-project.sh
        if (name in isopen) next
        s = 0   # a folder also counts its subfolders
        for (q in score) if (q == dir || index(q, dir "/") == 1) s += score[q]
        short = dir; if (index(short, home) == 1) short = "~" substr(short, length(home) + 1)
        if (name in rhost) {   # session on a server, no window yet: listed first
          t = rtitle[name]; sub(/^[^ ]+ /, "", t)
          printf "%f\tdir:%s\t%s\tsrv\t%s\t%s\t%s\t%s\t%s\t0\n", 1e9 + s, dir, name, rstate[name], t, rrc[name], name, rhost[name]
          next
        }
        printf "%f\tdir:%s\t%s\tdir\t\t%s\t\t%s\t\t0\n", s, dir, name, short, name
      }' | sort -s -t $'\t' -k1,1 -g -r | cut -f2-
}

# Formats rows into aligned, colored lines. Runs byte-wise (LC_ALL=C) and
# measures width by skipping UTF-8 continuation bytes, so umlauts align.
list() {
  rows "$1" | LC_ALL=C awk -F '\t' -v cur="$(tmux display -p '#{E:@project-name}')" '
    function width(s,  t) { t = s; gsub(/[\200-\277]/, "", t); return length(t) }
    function fit(s, n) {
      if (width(s) > n) {
        while (width(s) > n - 1) { s = substr(s, 1, length(s) - 1); sub(/[\300-\377][\200-\277]*$/, "", s) }
        s = s "…"
      }
      return s sprintf("%" (n - width(s)) "s", "")
    }
    {
      name = fit($7, 22)
      hc = "\033[35m"
      if ($3 == "dir") {
        printf "%s\t%s\t\033[2m○ %s               %s\033[0m\n", $1, $2, name, $5
        next
      }
      # ✻ = Claude Code runs here, state as colored word, 📡 = Remote Control on
      if      ($4 == "working") st = "\033[34marbeitet\033[0m"
      else if ($4 == "waiting") st = "\033[33;1mwartet  \033[0m"
      else if ($4 == "done")    st = "\033[32mfertig  \033[0m"
      else if ($4 == "idle")    st = "bereit  "
      else if ($4 == "remote")  st = sprintf("%s%-8s\033[0m", hc, $8)
      else                      st = "        "
      # coloured ✻ = runs on a Claude server, like its tab (pink)
      claude = ($8 != "") ? hc "✻\033[0m" : ($4 != "") ? "\033[38;5;173m✻\033[0m" : " "
      rc = ($6 != "") ? "📡" : "  "
      mark = ($7 == cur) ? "\033[1m●\033[0m" : "●"
      more = ($9 > 0) ? sprintf("  \033[2m+%d\033[0m", $9) : ""
      # srv = the session runs on a server, but no window here is connected to it
      if ($3 == "srv") more = more sprintf("  %s⇢ %s, nicht verbunden\033[0m", hc, $8)
      printf "%s\t%s\t%s %s %s %s %s %s%s\n", $1, $2, mark, name, claude, st, rc, $5, more
    }'
}

if [ "$1" = --list ]; then
  list "$2"
  exit 0
fi

sel=$(list | fzf --ansi --sync --reverse --exact --tiebreak=begin,index --delimiter='\t' --with-nth=3 \
  --border=rounded --border-label=' Projekte ' --border-label-pos=3 \
  --prompt='Projekt > ' \
  --header='Enter: springen · Ctrl+A: alle Fenster · Ctrl+X: Fenster schliessen · Ctrl+P: Vorschau · Ctrl+Space: zu' \
  --preview='case {1} in dir:*) ls -1 "$(echo {1} | cut -c5-)";; *) tmux capture-pane -ep -t {1};; esac' \
  --preview-window='right,55%,hidden' \
  --bind='ctrl-p:toggle-preview' \
  --bind='ctrl-space:abort' \
  --bind="ctrl-a:transform:case \$FZF_PROMPT in Alle*) echo 'change-prompt(Projekt > )+reload($0 --list)';; *) echo 'change-prompt(Alle Fenster > )+reload($0 --list all)';; esac" \
  --bind="ctrl-x:execute-silent(case {1} in @*) [ {1} != \"\$(tmux display -p '#{window_id}')\" ] && tmux kill-window -t {1};; esac)+reload:case \$FZF_PROMPT in Alle*) $0 --list all;; *) $0 --list;; esac") || exit 0

target=$(cut -f1 <<<"$sel")
session=$(cut -f2 <<<"$sel")

case $target in
  dir:*)
    tmux new-session -d -s "$session" -c "${target#dir:}"
    tmux switch-client -t "$session" ;;
  *)
    tmux switch-client -t "$session"
    tmux select-window -t "$target" ;;
esac
