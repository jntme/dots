#!/bin/bash

brew install zsh tmux neovim/neovim/neovim python3 ag reattach-to-user-namespace curl
#brew tap caskroom/cask
#brew cask install iterm2

curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
pip3 install neovim

#make neovim to standard editor in nvim
git config --global core.editor "$(which nvim)"

brew install font-fira-code

chsh -s /usr/local/bin/zsh

rm -rf ~/.vim ~/.vimrc ~/.zshrc ~/.tmux ~/.tmux.conf ~/.config/nvim/init.vim ~/.ideavimrc

mkdir -p ~/.config ~/.config/nvim


ln -s ~/.dots/zshrc ~/.zshrc
ln -s ~/.dots/tmux.conf ~/.tmux.conf
ln -s ~/.dots/vimrc ~/.config/nvim/init.vim
ln -s ~/.dots/ideavim ~/.ideavimrc

curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim



echo "------------------------------"
echo "------------------------------\n\n"

#echo "-- setting 'show hidden files'"
#show hidden files in finder
#defaults write com.apple.finder AppleShowAllFiles YES

echo "Dont forget to install tpm and tmux plugins with CTRL + b, I"

# inspiration from http://wrotenwrites.com/a_modern_terminal_workflow_1/
