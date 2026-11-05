#!/usr/bin/env bash
# Prints "<project name><tab><project root>" for a folder:
#   ~/dev/work/shop/backend -> shop        (first level below a project root)
#   other git repos               -> name of the repo root
#   anything else                 -> name of the folder itself; ~ -> home
# Usage: claude-project.sh <dir>

PROJECT_ROOTS=(~/Claude)

dir=${1%/}
root=
for base in "${PROJECT_ROOTS[@]}"; do
  case $dir in
    "$base"/*) rest=${dir#"$base"/}; root="$base/${rest%%/*}"; break ;;
  esac
done
[ -n "$root" ] || root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)
[ -n "$root" ] || root=$dir

# tmux session names cannot contain "." or ":"; a leading dot is dropped
# (.dots -> dots) because names starting with "_" mark hidden sessions
if [ "$root" = "$HOME" ]; then name=home; else name=$(basename "$root"); name=$(printf '%s' "${name#.}" | tr '.:' '__'); fi
printf '%s\t%s\n' "$name" "$root"
