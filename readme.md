Attention! 
At the moment this discrption out of date - you need to fiddle around a bit to git it to work, dependent on your OS.


Usage
-----

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


Additional stuff not in the scripts yet:
----------------------------------------

Cloning of the Tmux Module Manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm



Comment
-------

These scripts basically install NeoVIM and zsh and link the configuration files to your home directory, where the different tools can find them. On Mac it adds curl, tmux and iterm2 because these are not installed per default.

At the moment there are config files for the following tools:

- zsh
- neovim / vim
- tmux
- visual studio code

-> if you use a different OS you're free to make pull request for it :)


