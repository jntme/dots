
autoload colors zsh/terminfo
colors

# prompt
precmd() { print "" }
PS1="⟩ "
RPS1="%{$fg[magenta]%}%20<...<%~%<<%{$reset_color%}"

# if tmux is installed, run it
if [ "$TMUX" = "" ]; then
  new-session -n $HOST
  tmux attach
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
  curl https://cdn.rawgit.com/zsh-users/antigen/v1.4.1/bin/antigen.zsh > ~/.antigen.zsh
fi
source ~/.antigen.zsh

#normal oh-my-zsh
#antigen use oh-my-zsh

# "highlighting on command line
antigen bundle zsh-users/zsh-syntax-highlighting

# "autosuggestions on command line
antigen bundle zsh-users/zsh-autosuggestions

# "git shorthand
antigen bundle git
antigen bundle vi-mode
antigen bundle rupa/z
antigen bundle common-aliases
antigen bundle colored-man-paged


if [[ "$OSTYPE" == "linux-gnu" ]]; then
  # ...
elif [[ "$OSTYPE" == "darwin"* ]]; then
  # Mac OSX
  antigen bundle brew
  antigen bundle brew-cask
  antigen bundle gem
  antigen bundle osx
  antigen bundle battery
elif [[ "$OSTYPE" == "cygwin" ]]; then
  # POSIX compatibility layer and Linux environment emulation for Windows
  antigen bundle cygwin
elif [[ "$OSTYPE" == "msys" ]]; then
  # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
elif [[ "$OSTYPE" == "win32" ]]; then
  # I'm not sure this can happen.
elif [[ "$OSTYPE" == "freebsd"* ]]; then
  # ...
else
  # Unknown.
fi

#aliases
alias vim="nvim"
alias cpwd="pwd | pbpaste"

alias grep='grep --color=auto'

alias study="cd '/Users/jnt/Dropbox/01-Berner Fachhochschule/05-Fruhlingssemester 2017'";

alias slp="pmset sleepnow"

#reload zsh config
alias reload!='source ~/.zshrc'

BASE16_SHELL=$DOTFILES/themes/base16-shell/
[ -n "$PS1" ] && [ -s $BASE16_SHELL/profile_helper.sh ] && eval "$($BASE16_SHELL/profile_helper.sh)"
