#!/usr/bin/env bash
# prefix+?: menu with all custom shortcuts. Each entry shows its real shortcut;
# the highlighted letter selects it directly inside the menu.
# Usage: menu.sh <client> <pane>

client=$1
pane=$2

tmux display-menu -c "$client" -t "$pane" -T '#[align=centre] Kürzel ' -x C -y C \
  '-Claude & Projekte' '' '' \
  'Projekt wechseln              Ctrl+Space' p "display-popup -E -B -w 80% -h 60% '~/.dots/tmux/claude-switcher.sh'" \
  'Nächste wartende Session      prefix Space' n "run-shell -b '~/.dots/tmux/claude-next.sh \"#{client_name}\" \"#{pane_id}\"'" \
  'Schnell-Claude                Ctrl+Y' c "display-popup -E -w 80% -h 80% -T ' Claude ' '~/.dots/tmux/claude-popup.sh'" \
  'lazygit                       Ctrl+G' g "display-popup -E -w 90% -h 90% -d '#{pane_current_path}' -T ' lazygit ' lazygit" \
  '' \
  '-Fenster & Panes' '' '' \
  'Neues Fenster                 Ctrl+T' t 'new-window' \
  'Teilen: nebeneinander         prefix |' '|' "run-shell -b '~/.dots/tmux/split.sh #{pane_id} -h'" \
  'Teilen: untereinander         prefix -' '-' "run-shell -b '~/.dots/tmux/split.sh #{pane_id} -v'" \
  'Lokal teilen                  prefix %' '%' "split-window -h -c '#{pane_current_path}'" \
  'Pane Vollbild an/aus          prefix z' z 'resize-pane -Z' \
  'Pane schliessen               Ctrl+W' w 'kill-pane' \
  'Fenster umbenennen            prefix ,' , 'command-prompt -I "#W" "rename-window -- \"%%\""' \
  'Session umbenennen            prefix $' '$' 'command-prompt -I "#S" "rename-session -- \"%%\""' \
  '' \
  '-Sessions sichern' '' '' \
  'Jetzt speichern               prefix Ctrl-s' s 'run-shell ~/.tmux/plugins/tmux-resurrect/scripts/save.sh' \
  'Wiederherstellen              prefix Ctrl-r' r 'run-shell ~/.tmux/plugins/tmux-resurrect/scripts/restore.sh' \
  '' \
  'Konfiguration neu laden' R 'source-file ~/.tmux.conf ; display-message "tmux.conf neu geladen"' \
  'Alle tmux-Kürzel anzeigen' '?' 'list-keys'
