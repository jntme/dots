
autoload colors zsh/terminfo
colors

# prompt
precmd() { print "" }
PS1="⟩ "
RPS1="%{$fg[magenta]%}%20<...<%~%<<%{$reset_color%}"

# if tmux is installed, run it
if [ "$TMUX" = "" ]; then tmux; fi

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

antigen bundle osx 
antigen bundle vi-mode 
antigen bundle rupa/z
antigen bundle battery
antigen bundle common-aliases
antigen bundle colored-man-paged

# OS specific plugins
if [[ $CURRENT_OS == 'OS X' ]]; then
    antigen bundle brew
    antigen bundle brew-cask
    antigen bundle gem
    antigen bundle osx
elif [[ $CURRENT_OS == 'Linux' ]]; then
    # None so far...

    if [[ $DISTRO == 'CentOS' ]]; then
        antigen bundle centos
    fi
elif [[ $CURRENT_OS == 'Cygwin' ]]; then
    antigen bundle cygwin
fi

#aliases
alias vim="nvim"
alias cpwd="pwd | pbpaste"



alias study="cd '/Users/jnt/Dropbox/01-Berner Fachhochschule/05-Fruhlingssemester 2017'";





