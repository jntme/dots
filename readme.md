
Usage
-----

Clone and init of repo:

```bash
#cd to home dir first
git clone https://github.com/jntme/dots.git .dots
cd .dots
git submodule update --init
```


Don't forget to change your git credentials in the init file before starting a bash file!

If you use Ubuntu / Debian:

```bash
./init-linux.sh

```

If you use macOS:

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

Then press the prefix followed by a capital I: `Ctrl+b`, then `Shift+i`

To get the base16 look you need to type:

```
zsh
base16_eighties

```


Comment
-------

These scripts basically install NeoVIM and zsh and link the configuration files to your home directory, where the different tools can find them. On Mac it also installs tmux, curl and the Fira Code font via Homebrew. iTerm2 is not installed automatically; its settings are in `com.googlecode.iterm2.plist`.

At the moment there are config files for the following tools:

- zsh
- neovim / vim
- tmux
- visual studio code
- Claude Code (see below)

--> if you have any recommendations for improvements I'd love to get a pull request from you! :D


Claude Code with tmux
---------------------

tmux and zsh are set up for running many Claude Code sessions side by side,
optionally on a Mac mini that keeps them running while the laptop is closed.
Needs tmux >= 3.8, plus `fzf`, `jq` and `terminal-notifier` from Homebrew.

**What it does**

- One tmux session per project: starting `claude` in a folder moves its window
  into the session of its project. Projects are the folders below `~/Claude`
  (`PROJECT_ROOTS` in `tmux/claude-project.sh` and `tmux/claude-switcher.sh`),
  elsewhere the git root.
- Claude's state in the window name: ⠋ working, ✋ waiting for you, ✓ done
  (until you look at it), ✻ Claude runs here, 📡 Remote Control. Waiting
  sessions are also listed on the right of the status bar, and a macOS
  notification comes when a session in another window needs you or is done.
- Claude plan usage (as `/usage`) on the right of the status bar.
- Sessions survive a restart (tmux-resurrect + continuum, saved every 15 min);
  Claude panes resume their conversation.
- The themepack (gray) stays; the Claude parts are added after `run tpm`.

**Keys**

| Key | Action |
|---|---|
| `Ctrl+Space` | Project switcher, most recently used first (type to filter, Enter, Ctrl+A all windows, Ctrl+X close) |
| `Ctrl+Tab` | Toggle to the previous project (iTerm key mapping: Ctrl+Tab → escape sequence `[27;5;9~`) |
| prefix `Space` | Jump to the next Claude session waiting for you (✋), then finished ones (✓) |
| prefix `?` | Menu with all shortcuts |
| `Ctrl+Y` | Scratch Claude in a popup; Ctrl+Y again hides it, the conversation stays |
| `Ctrl+G` | lazygit in the current folder (`q` closes it) |
| prefix `\|` / `_` | Split in the same folder; in a window on the Mac mini (pink tab) a shell there |
| prefix `\` / `-` | Split full height / without path (always local), as before |
| `Ctrl+V` | In a pink window: paste a clipboard image into the Claude on the mini |
| prefix `Ctrl+s` / `Ctrl+r` | Save / restore the tmux sessions by hand |

**Mac mini as Claude server (optional)**

Sessions run in an invisible tmux on the mini (`tmux -L claude`, started by a
LaunchAgent in the graphical login, so Claude and `gh` use the keychain). The
laptop only attaches over SSH; closing a pane or the laptop does not end them.
Needs the same user name on both machines, an SSH host alias `mini`
(`macos/ssh-config-laptop`) and the server in `tmux/claude-hosts`.

| Command (laptop) | Action |
|---|---|
| `claude` | Local, unless the project lives on the mini: then connects to (or starts) its session there |
| `claude @mini` / `claude --local` | Choose the place |
| `claude-move` | Move the project and its Claude history to the mini (local backup) |
| `claude-move local` | Bring it back (`/exit` the session on the mini first) |
| `mini` | Shell on the mini, in the same folder inside a project that lives there |

On the mini: same `~/.dots` (`rsync -a ~/.dots/ mini:.dots/`), `~/.zshrc`
linked, `~/.zshenv` with the Homebrew PATH, Claude Code installed, and the
LaunchAgent from `macos/claude-tmux.plist` in `~/Library/LaunchAgents/`
(its presence makes the zshrc treat the machine as a server: ⚙ in the prompt).
Log in once via Screen Sharing (`claude`, `gh auth login`), then close the
window without logging out. After a restart (FileVault) unlock it and log in
again.

**Files**

| Path | Purpose |
|---|---|
| `tmux.conf` | Claude blocks are marked `--- Claude Code setup ---` |
| `zshrc` | `claude`, `claude-move`, `mini`, ⚙ prompt; no tmux autostart over SSH |
| `tmux/` | Scripts: status bar, switcher, Claude hooks, usage, splits, server sessions |
| `tmux/claude-hooks.json` | Claude Code hooks, merged into `~/.claude/settings.json` |
| `tmux/claude-hosts` | The Claude server; comment it out to keep everything local |
| `tmux/server.conf` | The invisible tmux on the mini |
| `claude/` | Claude theme for base16 colours (`dark-ansi-soft`), skill `mac-mini-remote`, example settings |
| `macos/` | LaunchAgent for the mini, `~/.ssh/config` template |

Claude Code settings (`~/.claude/settings.json`): the hooks from
`tmux/claude-hooks.json`, `"tui": "fullscreen"`, `"theme": "custom:dark-ansi-soft"`
(theme linked to `~/.claude/themes/`, skill to `~/.claude/skills/`).
