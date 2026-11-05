#!/bin/bash

brew install zsh tmux neovim the_silver_searcher curl
brew install --cask font-fira-code
#brew install --cask iterm2

git -C ~/.dots submodule update --init

#make neovim to standard editor in nvim
git config --global core.editor "$(which nvim)"

# homebrew lives in /opt/homebrew on Apple Silicon, /usr/local on Intel
ZSH_PATH="$(brew --prefix)/bin/zsh"
grep -qx "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" | sudo tee -a /etc/shells
chsh -s "$ZSH_PATH"

rm -rf ~/.vim ~/.vimrc ~/.zshrc ~/.tmux ~/.tmux.conf ~/.config/nvim/init.vim ~/.ideavimrc

mkdir -p ~/.config ~/.config/nvim


ln -s ~/.dots/zshrc ~/.zshrc
ln -s ~/.dots/tmux.conf ~/.tmux.conf
ln -s ~/.dots/vimrc ~/.config/nvim/init.vim
ln -s ~/.dots/ideavim ~/.ideavimrc

curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim



printf -- "------------------------------\n"
printf -- "------------------------------\n\n"

#echo "-- setting 'show hidden files'"
#show hidden files in finder
#defaults write com.apple.finder AppleShowAllFiles YES

echo "Dont forget to install the tmux plugins with CTRL + b, I"

# inspiration from http://wrotenwrites.com/a_modern_terminal_workflow_1/
