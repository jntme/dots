
#autoload colors zsh/terminfo
#colors

# prompt
precmd() { print "" }
PS1="⟩ "
RPS1="%F{magenta}%20<...<%~%<<%f"

# Base16 Shell
BASE16_SHELL="$HOME/.dots/base16-shell/"
[ -n "$PS1" ] && \
    [ -s "$BASE16_SHELL/profile_helper.sh" ] && \
        eval "$("$BASE16_SHELL/profile_helper.sh")"

# if tmux is installed, run it (attach to the last session or start a new one)
if command -v tmux >/dev/null && [ -z "$TMUX" ]; then
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
export PATH="$HOME/.local/bin:$PATH"

# loads the bundles and runs compinit
antigen apply


#add vi behaviour to zsh
#bindkey -v

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
