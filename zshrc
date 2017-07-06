
autoload colors zsh/terminfo
colors

# prompt
precmd() { print "" }
PS1="⟩ "
RPS1="%{$fg[magenta]%}%20<...<%~%<<%{$reset_color%}"

# if tmux is installed, run it
if [ "$TMUX" = "" ]; then
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
  curl -L git.io/antigen > ~/.antigen.zsh
fi
source ~/.antigen.zsh

#normal oh-my-zsh
#antigen use oh-my-zsh
#antigen theme pmcgee
#antigen theme candy

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
antigen bundle olivierverdier/zsh-git-prompt



if [[ "$OSTYPE" == "linux-gnu" ]]; then
  # ...
elif [[ "$OSTYPE" == "darwin"* ]]; then
  # Mac OSX
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

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Create a JAVA_HOME variable, determined dynamically
#export JAVA_HOME=$(/usr/libexec/java_home)
#export ANDROID_HOME=$HOME/Android/Sdk
# Add that to the global PATH variable
#export PATH=${JAVA_HOME}/bin:$PATH
# Add the Android SDK to the PATH variable
#export PATH=${PATH}:~/Library/Android/sdk/tools:~/Library/Android/sdk/platform-tools
