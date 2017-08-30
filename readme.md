
Usage
-----

Clone and init of repo:

```bash
#cd to home dir first
git clone https://github.com/jntme/dots.git .dots

git submodule init
git submodule update
```


Don't forget to change your git credentials in the init file before starting a bash file!

If you use Ubuntu:

```bash
./init-ubuntu.sh

```

If you use Mac OS X:

```bash
./init-mac.sh

```


After that you should install the VIM Plugins. Open vim and enter:

```
:PlugInstall

```

Then you should install the TMUX Packet Manager (tpm) as the plugins:

To do that, firstly open a new tmux session:

```
tmux

```

Then press `Ctrl+I` (big I!)


Comment
-------

These scripts basically install NeoVIM and zsh and link the configuration files to your home directory, where the different tools can find them. On Mac it adds curl, tmux and iterm2 because these are not installed per default.

At the moment there are config files for the following tools:

- zsh
- neovim / vim
- tmux
- visual studio code

--> if you have any recommendations for improvements I'd love to get a pull request from you! :D
