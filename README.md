# My dotfiles

## Install software

Depending on your OS follow one of these guides:
- [ArchLinux](./README-arch.md)
- [Asahi Fedora 39](./README-asahi.md)
- [OS X](./README-osx.md)


## Install configuration

```sh
git clone git@github.com:gotha/dotfiles.git && cd dotfiles
stow -t ~ .
```

### neovim

Install all plugins

```
nvim +PackerSync
```

### tmux

Start `tmux` and press `prefix` + `I` (shift + i) to install the required plugins.

### Vale

```sh
vale sync
```

to update vale styles

### Firefox

to hide tab bar open `about:config` and enable `toolkit.legacyUserProfileCustomizations.stylesheets`
while you are here you can disable Pocket by setting `extensions.pocket.enabled` to `false`.

```sh
cd ~/.mozilla/firefox/ && \
cd $(ls -d *.default-*) && \
ln -s ../xxx.profile-xxx/chrome .
```

## Usage

### Hammerspoon

The prefix is `Ctrl + Option + Cmd`

| shortcut               | effect                                                                  |
| -----------------------|-------------------------------------------------------------------------|
| `prefix` + `0`         | "maximize" or resize current window                                     |
| `prefix` + `9`         | send window to the other screen (assumes that you have only 2 monitors) |
| `prefix` + ➡️           | resize window to fit into the right half of the screen                   |
| `prefix` + ⬅️           | resize window to fit into the left half of the screen                  |
| `prefix` + ⬆️           | resize window to fit into the top half of the screen                    |
| `prefix` + ⬇️           | resize window to fit into the bottom half of the screen                 |

## Tmux

The prefix in this configuration is `Ctrl + Space`


| shortcut                    | effect                                                      |
| ----------------------------|-------------------------------------------------------------|
| `prefix` + `\|`             | split vertically                                            |
| `prefix` + `_`              | split horizontaly                                           |
| `prefix` + `h` `j` `k` `l`  | move to panel in the selected direction (vim style)         |
| `prefix` + `H` `J` `K` `L`  | resize panel in selected direction (vim style)              |
| `prefix` + `c`  	      | create new workspace (tab)                                  |
| `prefix` + `C`  	      | create new window                                           |
| `prefix` + `n`  	      | next window                                                 |
| `prefix` + `p`    	      | previous window                                             |
| `prefix` + `w`  	      | view all windows                                            |
| `prefix` + `S`  	      | save current session                                        |
| `prefix` + `R`  	      | restore last saved session (useful after restart)           |
| `prefix` + `d`  	      | detach from current tmux session (you can reattach with `tmux attach`) |
| `prefix` + `[`  	      | enter in normal mode (navigate with hjkl, select text with `shift + v` and copy with `y`)|
| `prefix` + `{`  	      | switch the places of left and right panel                   |


