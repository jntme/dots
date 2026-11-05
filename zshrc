
#autoload colors zsh/terminfo
#colors

# prompt
precmd() { print "" }
# agnoster (powerline segments: path, git), loaded with antigen below;
# the old minimal prompt was:
#PS1="⟩ "
#RPS1="%F{magenta}%20<...<%~%<<%f"

# Base16 Shell
BASE16_SHELL="$HOME/.dots/base16-shell/"
[ -n "$PS1" ] && \
    [ -s "$BASE16_SHELL/profile_helper.sh" ] && \
        eval "$("$BASE16_SHELL/profile_helper.sh")"

# Before starting tmux: the tmux server keeps this PATH, and its popups
# (Ctrl+Y) start claude from ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

# if tmux is installed, run it (attach to the last session or start a new one);
# not via SSH (e.g. `mini`, splits onto the Claude server)
if command -v tmux >/dev/null && [ -z "$TMUX" ] && [ -z "$SSH_CONNECTION" ]; then
  tmux -2 attach 2>/dev/null || tmux -2 new-session
fi

# auto cd into directory
setopt auto_cd

# do spellchecking
setopt correctall
alias git='nocorrect git'


# antigen stuff
if [[ ! -f ~/.antigen.zsh ]]; then
  curl -L git.io/antigen > ~/.antigen.zsh
fi
source ~/.antigen.zsh

#normal oh-my-zsh
#antigen use oh-my-zsh
#antigen theme pmcgee
#antigen theme candy
antigen theme agnoster

# "autosuggestions on command line
antigen bundle zsh-users/zsh-autosuggestions

# "git shorthand
antigen bundle git
antigen bundle rupa/z
antigen bundle olivierverdier/zsh-git-prompt



if [[ "$OSTYPE" == darwin* ]]; then
  # Mac OSX
  antigen bundle gem
  antigen bundle macos
  antigen bundle battery
fi

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
fpath=(~/.grok/completions/zsh $fpath)
# <<< grok installer <<<

# loads the bundles and runs compinit
antigen apply
setopt promptsubst

# agnoster's git segment took ~150 ms per prompt (vcs_info, several git calls);
# the same output from a single git status: branch, ↱ ahead / ↰ behind / ⇅ both,
# ± unstaged, ✚ staged, <B> bisect, >M< merge, >R> rebase
prompt_git() {
  local st line head oid ab staged unstaged dirty mode git_dir branch_char
  st=$(command git status --porcelain=v2 --branch 2>/dev/null) || return
  for line in ${(f)st}; do
    case $line in
      '# branch.head '*) head=${line#\# branch.head } ;;
      '# branch.oid '*) oid=${line#\# branch.oid } ;;
      '# branch.ab '*) ab=${line#\# branch.ab } ;;
      [12u]' '*) dirty=1; [[ $line[3] != . ]] && staged='✚'; [[ $line[4] != . ]] && unstaged='±' ;;
      '? '*) dirty=1 ;;
    esac
  done
  () { local LC_ALL="" LC_CTYPE="en_US.UTF-8"; branch_char=$''; }
  case $ab in
    '+0 -0' | '') ;;
    '+0 '*) branch_char=$'↰' ;;
    *' -0') branch_char=$'↱' ;;
    *) branch_char=$'⇅' ;;
  esac
  git_dir=$(command git rev-parse --git-dir 2>/dev/null)
  if [[ -e $git_dir/BISECT_LOG ]]; then mode=" <B>"
  elif [[ -e $git_dir/MERGE_HEAD ]]; then mode=" >M<"
  elif [[ -e $git_dir/rebase || -e $git_dir/rebase-apply || -e $git_dir/rebase-merge ]]; then mode=" >R>"
  fi
  if [[ -n $dirty ]]; then
    prompt_segment "$AGNOSTER_GIT_DIRTY_BG" "$AGNOSTER_GIT_DIRTY_FG"
  else
    prompt_segment "$AGNOSTER_GIT_CLEAN_BG" "$AGNOSTER_GIT_CLEAN_FG"
  fi
  if [[ $head == '(detached)' ]]; then head="➦ ${oid[1,7]}"; else head="$branch_char $head"; fi
  local flags=$unstaged$staged
  echo -n "${head:gs/%/%%}${flags:+ $flags}${mode}"
}


#add vi behaviour to zsh
bindkey -v

#aliases
alias vim="nvim"
alias cpwd="pwd | pbcopy"

alias grep='grep --color=auto'

alias slp="pmset sleepnow"

#reload zsh config
alias reload!='source ~/.zshrc'

alias ls="ls -G"
alias ll="ls -lG"

alias vsc="open -a Visual\ Studio\ Code ."

alias tt="timetrap"
alias ttd="tt display"
alias tte="tt edit"
alias tti="tt in"
alias tto="tt out"
alias tts="tt sheet"
alias ttl="tt list"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# --- Claude Code setup (see readme.md, "Claude Code with tmux") ---
# Claude servers (Mac minis), see ~/.dots/tmux/claude-hosts. This machine is
# one if it starts the anchor tmux (LaunchAgent macos/claude-tmux.plist).
_claude_servers=(${(f)"$(awk '!/^#/ && NF { print $1 }' ~/.dots/tmux/claude-hosts 2>/dev/null)"})
# _claude_server = its name in claude-hosts (by name or hostname), empty on the laptop.
_claude_server=
if [[ -f ~/Library/LaunchAgents/local.claude-tmux.plist ]]; then
  _claude_server=$(awk -v h="${HOST%%.*}" '!/^#/ && NF && ($1 == h || $3 == h) { print $1; exit }' ~/.dots/tmux/claude-hosts)
  : ${_claude_server:=mini}
fi

# agnoster's context segment: only ⚙ on a Claude server or via SSH, pink like
# the server's tabs (instead of user@host everywhere)
prompt_context() {
  [[ -n $_claude_server || -n $SSH_CONNECTION ]] && prompt_segment magenta black "⚙"
}
# newer agnoster versions call tf_prompt_info from the terraform plugin (not loaded)
prompt_terraform() {}

# Claude Code: runs on a Claude server for projects that live there (.claude-host
# in the project or ~/.config/claude-remote/projects), otherwise locally.
# `claude @mini …` / `claude --local …` choose the place.
# On a server itself, `claude` in a project attaches to (or starts) the
# project's session in the anchor tmux, the same one the laptop connects to;
# `claude --here …` runs a separate one in the current shell.
claude() {
  local where= project root
  if [[ -n $_claude_server ]]; then
    IFS=$'\t' read -r project root < <(~/.dots/tmux/claude-project.sh "$PWD")
    if [[ $1 == --here || $root == $HOME ]] || ! tmux -L claude run-shell true 2>/dev/null; then
      [[ $1 == --here ]] && shift
      command claude "$@"
    else
      TMUX= tmux -L claude new-session -A -s "$project" -c "$PWD" "claude --remote-control ${(q)project} ${(j: :)${(q)@}}"
    fi
    return
  fi
  case $1 in
    @*) where=${1#@}; shift ;;
    --local) where=local; shift ;;
  esac
  [[ -n $where ]] || where=$(~/.dots/tmux/claude-remote.sh where "$PWD" | cut -f1)
  if [[ $where == local ]]; then
    command claude "$@"
  else
    CLAUDE_REMOTE_HOST=$where ~/.dots/tmux/claude-remote.sh run "$PWD" "$@"
  fi
}
alias claude-move='~/.dots/tmux/claude-move'

# SSH to a Claude server: `mini`. In a project that lives there (see
# claude above) it opens a shell in the same folder; with arguments it is plain ssh.
_claude_server_ssh() {
  local host=$1 where
  shift
  where=$(~/.dots/tmux/claude-remote.sh where "$PWD" | cut -f1)
  if [[ $# -eq 0 && $where == $host ]]; then
    ssh -t "$host" "cd ${(q)PWD} 2>/dev/null || echo '${PWD/#$HOME/~} does not exist on $host'; exec \$SHELL -l"
  else
    ssh "$host" "$@"
  fi
}

# Entering a project that lives on the mini: the local folder is (nearly)
# empty, so point to the remote side once per project
_claude_remote_hint() {
  local where project
  IFS=$'\t' read -r where _ < <(~/.dots/tmux/claude-remote.sh where "$PWD")
  [[ $where == local ]] && { _claude_remote_hint_for=; return }
  project=$(~/.dots/tmux/claude-project.sh "$PWD" | cut -f1)
  [[ $project == $_claude_remote_hint_for ]] && return
  _claude_remote_hint_for=$project
  print -P "%F{5}⚙ $project lives on $where%f – \"claude\" connects to its session, \"$where\" opens a shell there"
}
[[ -n $_claude_server ]] || { autoload -U add-zsh-hook; add-zsh-hook chpwd _claude_remote_hint }

# Unlock a Claude server (FileVault) via SSH after a restart, then wait until it is up.
# Uses the SSH hosts <server>-unlock and <server>-admin.
_claude_server_unlock() {
  local host=$1
  echo "Waiting for $host (port 22) …"
  until nc -z -G 2 "$(ssh -G $host-unlock | awk '/^hostname /{print $2}')" 22 2>/dev/null; do sleep 3; done
  if ssh -o BatchMode=yes -o ConnectTimeout=3 $host-admin true 2>/dev/null; then
    echo "$host is not locked."; ssh $host-admin 'fdesetup status'; return 0
  fi
  ssh $host-unlock
  echo "Unlocked – waiting for the system to start …"
  until ssh -o BatchMode=yes -o ConnectTimeout=3 $host-admin true 2>/dev/null; do sleep 5; done
  ssh $host-admin 'fdesetup status'
}

# Per server: <server> (shell), <server>-admin, <server>-unlock
for _h in $_claude_servers; do
  eval "$_h() { _claude_server_ssh $_h \"\$@\" }; $_h-unlock() { _claude_server_unlock $_h }; alias $_h-admin='ssh $_h-admin'"
done
unset _h

# Ping the Mac mini (address from the SSH host alias `mini`); args go to ping, e.g. `pingmm -c 3`
pingmm() { ping "$@" "$(ssh -G mini | awk '/^hostname /{print $2}')" }
# --- end Claude Code setup ---
