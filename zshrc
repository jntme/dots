
autoload colors zsh/terminfo
colors

# prompt
precmd() { print "" }
PS1="⟩ "
RPS1="%{$fg[magenta]%}%20<...<%~%<<%{$reset_color%}"

# if tmux is installed, run it
if [ "$TMUX" = "" ]; then
  tmux -2 attach
fi

# auto cd into directory
setopt auto_cd

# do spellchecking
setopt correctall
alias git status='nocorrect git status'

#make base16-shell work

BASE16_SHELL=$HOME/.dots/base16-shell/
[ -n "$PS1" ] && [ -s $BASE16_SHELL/profile_helper.sh ] && eval "$($BASE16_SHELL/profile_helper.sh)"

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
antigen bundle vi-mode
antigen bundle rupa/z
antigen bundle olivierverdier/zsh-git-prompt



if [[ "$OSTYPE" == "darwin" ]]; then
  # Mac OSX
  antigen bundle brew-cask
  antigen bundle gem
  antigen bundle osx
  antigen bundle battery
fi


#add vi behaviour to zsh
bindkey -v

#aliases
alias vim="nvim"
alias cpwd="pwd | pbcopy"

alias grep='grep --color=auto'

alias study="cd '/Users/jnt/Dropbox/01-Berner Fachhochschule/05-Fruhlingssemester 2017'";

alias slp="pmset sleepnow"

#reload zsh config
alias reload!='source ~/.zshrc'

alias ls="ls -G"
alias ll="ll -G"

alias vsc="open -a Visual\ Studio\ Code ."

alias tt="timetrap"
alias ttd="tt display"
alias tte="tt edit"
alias tti="tt in"
alias tto="tt out"
alias tts="tt sheet"
alias ttl="tt list"
