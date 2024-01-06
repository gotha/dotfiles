# My dotfiles

## Install dependencies

### OSX

Install tools:

```sh
xcode-select --install
```

install Nix:

```sh
sh <(curl -L https://nixos.org/nix/install)
```

install homebrew:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

set computer name if needed

```sh
sudo scutil --set ComputerName platypus
sudo scutil --set LocalHostName platypus
sudo reboot
```

remove old config files if needed

```sh
sudo mv /etc/shells /etc/shells.before-nix-darwin
```


Start with:

```sh
cd ~/.config/nix
nix --extra-experimental-features "nix-command flakes" build .#darwinConfigurations.platypus.system

./result/sw/bin/darwin-rebuild switch --flake  .
```

from that point on, after every change run):

```sh
darwin-rebuild switch --flake .
```


## Install configuration

Install [stow](https://www.gnu.org/software/stow/) first.

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


