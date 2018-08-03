#!/bin/bash

#install zshell
sudo apt-get install zsh

#install neovim
sudo apt-get install software-properties-common

sudo apt-get install python-dev python-pip python3-dev python3-pip

sudo add-apt-repository ppa:neovim-ppa/stable
sudo apt-get update
sudo apt-get install neovim

sudo update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 60
sudo update-alternatives --config vi
sudo update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 60
sudo update-alternatives --config vim
sudo update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 60
sudo update-alternatives --config editor

#not needed because of upper config
#git config --global core.editor "$(which nvim)"

#chsh -s /usr/bin/zsh
chsh -s /bin/zsh

rm -rf ~/.vim ~/.vimrc ~/.zshrc ~/.tmux ~/.tmux.conf ~/.config/nvim/init.vim

mkdir -p ~/.config ~/.config/nvim

ln -s ~/.dots/zshrc ~/.zshrc
ln -s ~/.dots/tmux.conf ~/.tmux.conf
ln -s ~/.dots/vimrc ~/.config/nvim/init.vim

#install vim plugin plugin
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

#set git config as well
git config --global user.email "mail@jntme.ch"
git config --global user.name "jntme"

