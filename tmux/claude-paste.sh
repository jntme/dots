#!/bin/bash
# Ctrl+V in a window connected to a Claude session on a server (coloured tab).
# Claude reads pasted images from the clipboard of the machine it runs on, so
# an image on the laptop's clipboard is copied to the server's clipboard first;
# then Ctrl+V goes on to the remote Claude, which shows it as [Image #n].
# A server without a graphical session for the user (login from a file) has no clipboard:
# there the image file's path is pasted instead, which Claude also attaches.
# Without an image (or if the server is unreachable) Ctrl+V passes through as is.
#   claude-paste.sh <pane> <host>
pane=$1 host=$2
pass() { tmux send-keys -t "$pane" C-v; exit; }

osascript -e 'clipboard info' 2>/dev/null | grep -qE 'PNGf|TIFF' || pass
file=$(mktemp -t claude-paste).png
trap 'rm -f "$file" "${file%.png}"' EXIT
osascript -e "set f to open for access POSIX file \"$file\" with write permission" \
  -e 'write (the clipboard as «class PNGf») to f' -e 'close access f' >/dev/null 2>&1 || pass

tmux display-message -t "$pane" "Copying image to $host …"
# One connection (ControlMaster): store the image, keep a day of them, put it
# on the clipboard; prints the file's path when the clipboard did not take it
remote=$(ssh -o BatchMode=yes -o ConnectTimeout=3 "$host" '
  dir=~/.cache/claude-paste; mkdir -p $dir; find $dir -type f -mtime +1 -delete
  f=$dir/$(date +%Y%m%d-%H%M%S).png; cat > $f || exit 1
  osascript -e "set the clipboard to (read (POSIX file \"$f\") as «class PNGf»)" >/dev/null 2>&1
  osascript -e "clipboard info" 2>/dev/null | grep -q PNGf || echo "$f"' <"$file") ||
  { tmux display-message -t "$pane" "Could not copy the image to $host"; pass; }
[ -z "$remote" ] && pass
# Bracketed paste of the path, as if the file had been dropped into the terminal
tmux set-buffer -b claude-paste "$remote " \; paste-buffer -p -d -b claude-paste -t "$pane"
